import 'dart:convert';
import 'dart:io';

import 'package:assignment1/protocol-info.dart';

class PublisherProcess {
  Future<void> publish(
      {required String message,
      required InternetAddress broker,
      required int port}) async {
    try {
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0,
              reusePort: true, reuseAddress: true)
          .then((RawDatagramSocket socket) {
        socket.broadcastEnabled = true;
        socket.send(
            AsciiCodec().encode(
                json.encode(ProtocolInfo(type: 'pub', info: message).toJson())),
            broker,
            port);
        socket.listen((RawSocketEvent event) {
          var datagram = socket.receive();
          if (datagram is Datagram &&
              ProtocolInfo.fromJson(
                          json.decode(AsciiCodec().decode(datagram.data)))
                      .type ==
                  PUBSUB.ACK) {
            print('Ack: Broker ${datagram.address.address}');
          }
        });
      });
    } on SocketException catch (e, s) {
      stderr.addError(e, s);
      return;
    } catch (e, s) {
      stderr.addError(e, s);
    }
  }
}
