import 'dart:convert';
import 'dart:io';

import 'package:assignment1/protocol-info.dart';

class SubscriberProcess {
  Future<void> createSubscriberProcess(
      {required int port, required Set<String> subjects}) async {
    // Create datagram socket and bind to any ip address and the provided port
    try {
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, 50001,
              reuseAddress: true, reusePort: true)
          .then((RawDatagramSocket socket) {
        //broker = InternetAddress(broker);
        socket.broadcastEnabled = true;
        socket.send(
            AsciiCodec().encode(json.encode(ProtocolInfo(
                    type: PUBSUB.SUB,
                    source: socket.address,
                    subject: 'register',
                    info: subjects.toString())
                .toJson())),
            InternetAddress('255.255.255.255'),
            port);

        socket.listen((RawSocketEvent event) {
          // recieve datagram from socket if read event
          if (event == RawSocketEvent.read) {
            var datagram = socket.receive();
            // ensure datagram not null
            if (datagram is Datagram) {
              // pull data from datagram and convert into string
              final recieved = ProtocolInfo.fromJson(
                  json.decode(AsciiCodec().decode(datagram.data)));
              // handle acknowledgement
              if (datagram.address.address != recieved.source.address) {
                if (recieved.type == PUBSUB.FORWARD) {
                  var size = socket.send(
                      AsciiCodec().encode(json.encode(
                          ProtocolInfo.ack(recieved.source, recieved.subject))),
                      datagram.address,
                      port);
                  print(
                      'Recieved: ${json.decode(AsciiCodec().decode(datagram.data))} from ${datagram.address.address}:$port');
                  print('sent ack of $size bytes');
                } else if (recieved.type == PUBSUB.ACK) {
                  print(
                      'Ack: ${datagram.address.address}, Subject: ${recieved.subject}');
                }
              }
            }
          }
        });
      });
    } on SocketException catch (e, s) {
      print(e.toString());
      print(s.toString());
      stderr.addError(e, s);
      return;
    } catch (e, s) {
      print(e.toString());
      print(s.toString());
      stderr.addError(e, s);
      return;
    }
  }
}
