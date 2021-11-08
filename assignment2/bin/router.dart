import 'dart:collection';
import 'dart:io';
import 'message.dart';

class Router {
  Map<String, Set<InternetAddress>> routingTable = {};
  Router();

  Future<void> forward() async {
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, 51510)
        .then((RawDatagramSocket socket) {
      socket.listen((RawSocketEvent event) {
        var dg = socket.receive();
        if (dg is Datagram) {
          Message message = Message.fromAsciiEncoded(dg.data);
          if (message.header.type == Type.networkId) {
            InternetAddress.lookup(message.header.value as String).then(
                (value) => routingTable
                    .addAll({message.header.value as String: value.toSet()}));
            routingTable.entries
                .where((element) => element.key == message.header.value)
                .forEach((element) {
              for (var element in element.value) {
                stdout.writeln('sent to $element');
                print('sent to $element');
                socket.send(dg.data, element, 51510);
              }
            });
          }
        }
      });
    });
  }
}
