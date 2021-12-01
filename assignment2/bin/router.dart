import 'dart:collection';
import 'dart:convert';
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
        if ((message.header.value is String) &&
            ((message.header.value as String) == 'controller')) {
          //print(message.header.value);
          print(jsonEncode(message.toJson()));
        }
        InternetAddress.lookup((message.header.value as NetworkId).location)
            .then(
          (value) => socket.send(dg.data, value.first, 51510),
        )
            .catchError((e) {
          Iterable<FlowEntry> route = flowTable.flowTable.where(
              (element) => element.dest == (message.header.value as NetworkId));
          if (route.isEmpty) {
            print('looking for controller');
            print(jsonEncode(message.toJson()));
            InternetAddress.lookup('controller').then((value) => socket.send(
                Message(
                        header: TLV(type: Type.combo, length: 2, value: {
                          TLV(
                              type: Type.flow,
                              length: (message.header.value as NetworkId)
                                  .toString()
                                  .length,
                              value: message.header.value.toString()),
                          message.header
                        }),
                        payload: message.payload)
                    .toAsciiEncoded(),
                value.first,
                51510));
          } else if (route.length == 1) {
            if (route.first.egress != null) {
              print('looking for ${route.first.egress}');
              InternetAddress.lookup(route.first.egress!).then(
                (value) =>
                    socket.send(message.toAsciiEncoded(), value.first, 51510),
              );
            } else {
              print(
                  'looking for ${(message.header.value as NetworkId).location}');
              InternetAddress.lookup(
                      (message.header.value as NetworkId).location)
                  .then(
                (value) => routingTable.addAll(
                  {(message.header.value as NetworkId).location: value.toSet()},
                ),
              );
              routingTable.entries
                  .where((element) =>
                      element.key ==
                      (message.header.value as NetworkId).location)
                  .forEach(
                (element) {
                  for (var element in element.value) {
                    socket.send(message.toAsciiEncoded(), element, 51510);
                  }
                },
              );
            }
          } else {
            print(
                'Failed to forward packet to ${message.header.value} from ${dg.address.address}');
          }
          // though the value isnt used, the dart compiler requires a value of
          // the same type as the then() argument would return
          return 0;
        }, test: (e) => e is SocketException);
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
        print(message.header.value);
        flowTable.add(
          message.header.value is FlowEntry
              ? message.header.value as FlowEntry
              : FlowEntry.fromJson(message.header.value),
        );
        break;
    }
  }
}
