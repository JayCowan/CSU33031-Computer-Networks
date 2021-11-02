import 'dart:convert';
import 'dart:io';

import 'package:assignment1/protocol-info.dart';

class SubscriberProcess {
  Future<void> createSubscriberProcess(
      {required int port, required Set<String> subjects}) async {
    var hasRegistered = false;
    // Create datagram socket and bind to any ip address and the provided port
    try {
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, port,
              reuseAddress: true, reusePort: true)
          .then((RawDatagramSocket socket) {
        socket.broadcastEnabled = true;
        // Send a registry request to the broker
        socket.send(
            AsciiCodec().encode(json.encode(ProtocolInfo(
                    type: PUBSUB.SUB,
                    source: socket.address,
                    subject: 'register',
                    info: subjects.toString())
                .toJson())),
            InternetAddress('255.255.255.255'),
            port);
        // Begin listening for registration ack
        socket.listen((RawSocketEvent event) {
          // recieve datagram from socket if read event
          if (event == RawSocketEvent.read) {
            while (!hasRegistered) {
              var dg = socket.receive();
              if (dg is Datagram) {
                final ackRegister = ProtocolInfo.fromJson(
                    json.decode(AsciiCodec().decode(dg.data)));
                if (ackRegister.type == PUBSUB.ACK &&
                    ackRegister.subject == 'register') {
                  hasRegistered = true;
                  print('Registered');
                } else {
                  print('Awaiting registry');
                }
              }
            }
            var datagram = socket.receive();
            // ensure datagram not null
            if (datagram is Datagram) {
              // pull data from datagram and convert into string
              final recieved = ProtocolInfo.fromJson(
                  json.decode(AsciiCodec().decode(datagram.data)));
              // handle acknowledgement
              if (datagram.address.address != recieved.source.address) {
                // Forward indicates that this is a message to read, not an ack, 
                //  and was sent directly to the subscriber
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
                  // Ack for when subscribing to new subjects
                  print(
                      'Ack: ${datagram.address.address}, Subject: ${recieved.subject}');
                }
              }
            }
          }
        });
      }); 
    } on SocketException catch (e, s) {
      // Catch and report any socket issues, reporting them to both 
      //  print and add to stdErr
      print(e.toString());
      print(s.toString());
      stderr.addError(e, s);
      return;
    } catch (e, s) {
      // Any other issues reported here
      print(e.toString());
      print(s.toString());
      stderr.addError(e, s);
      return;
    }
  }
}
