import 'dart:collection';
import 'dart:io';
import 'controller.dart';
import 'flow_table.dart';
import 'message.dart';

class Router {
  Map<String, Set<InternetAddress>> routingTable = {};
  FlowTable flowTable = FlowTable();
  Router();

  Future<void> routerProcess() async {
    await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      51510,
      reuseAddress: false,
    ).then((RawDatagramSocket socket) {
      socket.listen((RawSocketEvent event) async {
        var dg = socket.receive();
        if (dg is Datagram) {
          Message message = Message.fromAsciiEncoded(dg.data);
          await _forward(dg, socket, message);
        }
      });
    });
  }

  Future<Message?> _forward(
      Datagram dg, RawDatagramSocket socket, Message message) async {
    switch (message.header.type) {
      case Type.networkId:
        Iterable<FlowEntry> route = flowTable.flowTable.where(
            (element) => element.dest == (message.header.value as String));
        if (route.isEmpty) {
          InternetAddress.lookup('controller').then((value) => socket.send(
              Message(
                      header: TLV(type: Type.combo, length: 2, value: {
                        TLV(
                            type: Type.flow,
                            length: (message.header.value as String).length,
                            value: message.header.value),
                        message.header
                      }),
                      payload: message.payload)
                  .toAsciiEncoded(),
              value.first,
              51510));
        } else if (route.length == 1) {
          if (route.first.egress != null) {
            InternetAddress.lookup(route.first.egress!).then(
              (value) =>
                  socket.send(message.toAsciiEncoded(), value.first, 51510),
            );
          } else {
            await InternetAddress.lookup(message.header.value as String).then(
                (value) => routingTable
                    .addAll({message.header.value as String: value.toSet()}));
            routingTable.entries
                .where((element) => element.key == message.header.value)
                .forEach((element) {
              for (var element in element.value) {
                socket.send(message.toAsciiEncoded(), element, 51510);
              }
            });
          }
        } else {
          print(
              'Failed to forward packet to ${message.header.value} from ${dg.address.address}');
        }
        break;
      case Type.combo:
        for (TLV element in message.header.value as Iterable<TLV>) {
          await _forward(
              dg, socket, Message(header: element, payload: message.payload));
        }
        break;
      case Type.flow:
        print('Dropping flow packet from ${dg.address.address}');
        break;
      case Type.update:
        flowTable.add(
          message.header.value is FlowEntry
              ? message.header.value as FlowEntry
              : FlowEntry.fromJson(message.header.value),
        );
        break;
    }
  }
}
