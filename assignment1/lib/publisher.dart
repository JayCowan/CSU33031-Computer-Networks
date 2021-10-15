import 'dart:convert';
import 'dart:io';

import 'package:assignment1/protocol-info.dart';

class PublisherProcess {
  Future<void> publish({required String message, required int port}) async {
    try {
      var _ackRecieved = false;
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0,
              reusePort: true, reuseAddress: true)
          .then((RawDatagramSocket socket) {
        socket.broadcastEnabled = true;
        var dg = AsciiCodec().encode(json.encode(ProtocolInfo(
                type: PUBSUB.PUB,
                source: socket.address,
                subject: message.split(': ').first,
                info: message.split(': ').last)
            .toJson()));
        socket.send(dg, InternetAddress('255.255.255.255'), port);
        socket.listen((RawSocketEvent event) {
          while (!_ackRecieved) {
            var datagram = socket.receive();
            if (datagram is Datagram) {
              final ackMessage = ProtocolInfo.fromJson(
                  json.decode(AsciiCodec().decode(datagram.data)));
              if (ackMessage.type == PUBSUB.ACK &&
                  ackMessage.subject == message.split(': ').first) {
                print('Ack: Broker ${datagram.address.address}');
                _ackRecieved = true;
              }
            }
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
