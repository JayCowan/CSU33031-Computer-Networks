import 'dart:convert';
import 'dart:io';

import 'package:assignment1/protocol-info.dart';

class PublisherProcess {
  Future<void> publish(
      {required String message,
      required InternetAddress broker,
      required int port}) async {
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, port)
        .then((RawDatagramSocket socket) {
      socket.broadcastEnabled = true;
      socket.send(
          Utf8Codec().encode(
              json.encode(ProtocolInfo(type: 'pub', info: message).toJson())),
          broker,
          port);
      socket.listen((RawSocketEvent event) {
        var datagram = socket.receive();
        if (ProtocolInfo.fromJson(
                    json.decode(Utf8Codec().decode(datagram!.data)))
                .type ==
            PUBSUB.ACK) {
          print('Ack: Broker ${datagram.address.address}');
          socket.close();
        }
      });
    });
  }
}
