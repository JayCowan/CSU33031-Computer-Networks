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
        //broker = InternetAddress('broker');

        socket.broadcastEnabled = true;
        socket.send(
            AsciiCodec().encode(json.encode(ProtocolInfo(
                    type: PUBSUB.PUB,
                    source: socket.address,
                    subject: 'chat',
                    info: message)
                .toJson())),
            InternetAddress.anyIPv4,
            port);
        print('tried to send connection to broker');
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
