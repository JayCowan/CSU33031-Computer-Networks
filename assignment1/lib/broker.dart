import 'dart:convert';
import 'dart:io';

import 'package:assignment1/protocol-info.dart';

class BrokerProcess {
  List<InternetAddress> subscribers = <InternetAddress>[];
  List<InternetAddress> publishers = <InternetAddress>[];

  static Future<void> publishProtocol(String message, int port) async {
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
        .then((RawDatagramSocket socket) {
      print('Now publishing from ${socket.address.address}:$port');
      socket.broadcastEnabled = true;

      if (socket.send(Utf8Codec().encode(message),
              InternetAddress('172.20.0.3'), port) !=
          0) {
        print('sent: $message to address :$port');
      } else {
        throw SocketException('failed to send message',
            address: InternetAddress.anyIPv4, port: port);
      }
    });
  }

  Future<void> fetchProtocol({required int port}) async {
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, port)
        .then((RawDatagramSocket socket) {
      socket.broadcastEnabled = true;
      socket.listen((RawSocketEvent event) {
        var datagram = socket.receive();
        var info = ProtocolInfo.fromJson(
            json.decode(Utf8Codec().decode(datagram!.data)));
        if (info.type == PUBSUB.PUB) {
          if (!publishers.contains(datagram.address)) {
            publishers.add(datagram.address);
          }
          socket.send(Utf8Codec().encode(json.encode(ProtocolInfo.ack())),
              datagram.address, port);
          subscribers.forEach((InternetAddress element) {
            socket.send(datagram.data, element, port);
          });
        } else if (info.type == PUBSUB.SUB) {
          if (!subscribers.contains(datagram.address)) {
            subscribers.add(datagram.address);
          }
          socket.send(Utf8Codec().encode(json.encode(ProtocolInfo.ack())),
              datagram.address, port);
        } else if (info.type == PUBSUB.ACK) {
          print('Ack: ${datagram.address.address}');
        } else if (info.type == PUBSUB.ERROR) {
          print('Unknown action in pubsub process with data ${info.info}');
        }
      });
    });
  }
}
