import 'dart:io';
import 'flow_table.dart';
import 'message.dart';

class Router {
  Map<String, Set<InternetAddress>> routingTable = {};
  FlowTable flowTable = FlowTable();

  Router();
  /// starts the forwarding process and completes on a Future<void>
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
  /// internal semi-recursive forwarding function
  Future<Message?> _forward(
      Datagram dg, RawDatagramSocket socket, Message message) async {
    switch (message.header.type) {
      case Type.networkId:
        print('looking for ${(message.header.value as NetworkId).location}');
        await InternetAddress.lookup(
                (message.header.value as NetworkId).location)
            .then(
          (value) => socket.send(dg.data, value.first, 51510),
        )
            .catchError((e) async {
          print(
              'couldn\'t find ${(message.header.value as NetworkId).location}');
          Iterable<FlowEntry> route = flowTable.flowTable.where((element) =>
              identical(element.dest.toString(),
                  (message.header.value as NetworkId)));
          print('route is $route');
          if (route.isEmpty) {
            await InternetAddress.lookup('controller')
                .then((value) => socket.send(
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
            return 0;
          } else if (route.length == 1) {
            print('route has length 1');
            if (route.first.egress != null) {
              print('looking for ${route.first.egress}');
              await InternetAddress.lookup(route.first.egress!).then(
                (value) =>
                    socket.send(message.toAsciiEncoded(), value.first, 51510),
              );
              return 0;
            } else {
              print(
                  'looking for ${(message.header.value as NetworkId).location}');
              await InternetAddress.lookup(
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
                  print(element);
                  for (var element in element.value) {
                    print(element);
                    socket.send(message.toAsciiEncoded(), element, 51510);
                  }
                },
              );
              return 0;
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
        Set<TLV> updates = (message.header.value as Iterable<TLV>)
            .where((element) => element.type == Type.update)
            .toSet();
        for (TLV elem in updates) {
          await _forward(
              dg, socket, Message(header: elem, payload: message.payload));
        }
        print('flowtable len is ${flowTable.flowTable.length}');
        Set<TLV> netIds = (message.header.value as Iterable<TLV>)
            .where((element) => element.type == Type.networkId)
            .toSet();
        for (var elem in netIds) {
          await _forward(
              dg, socket, Message(header: elem, payload: message.payload));
        }
        return null;
      //break;
      case Type.flow:
        print('Dropping flow packet from ${dg.address.address}');
        break;
      case Type.update:
        flowTable.add(message.header.value as FlowEntry);
        break;
    }
  }
}
