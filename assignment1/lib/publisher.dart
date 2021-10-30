import 'dart:convert';
import 'dart:io';

import 'package:assignment1/protocol-info.dart';

class PublisherProcess {
  // Publishers send messages when entered, and thus arent a continuous process
  //  like subscribers, and just send when a message is provided
  Future<void> publish({required String message, required int port}) async {
    try {
      var _ackRecieved = false;
      // Bind to generic port using any IPV4
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0,
              reusePort: true, reuseAddress: true)
          .then((RawDatagramSocket socket) {
        socket.broadcastEnabled = true;
        // Build a ProtocolInfo to send to the broker
        var dg = AsciiCodec().encode(json.encode(ProtocolInfo(
                type: PUBSUB.PUB,
                source: socket.address,
                subject: message.split(': ').first,
                info: message.split(': ').last)
            .toJson()));
        // Broadcast so that the broker can recieve it and so it can be
        //  intercepted by wireshark
        socket.send(dg, InternetAddress('255.255.255.255'), port);
        // Listen for an ack from the broker, then close out the process and
        //  accept new input
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
      // Add any Socket error and stacktrace to stderr
      stderr.addError(e, s);
      return;
    } catch (e, s) {
      // Add any generic error and stacktrace to stderr
      stderr.addError(e, s);
    }
  }
}
