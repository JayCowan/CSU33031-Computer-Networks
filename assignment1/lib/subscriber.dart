import 'dart:convert';
import 'dart:io';

import 'package:assignment1/protocol-info.dart';

class SubscriberProcess {
  Future<void> createSubscriberProcess({required int port}) async {
    // Create datagram socket and bind to any ip address and the provided port
    try {
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0,
              reuseAddress: true, reusePort: true)
          .then((RawDatagramSocket socket) {
        //broker = InternetAddress(broker);
        socket.broadcastEnabled = true;
        socket.send(
            AsciiCodec().encode(json.encode(ProtocolInfo(
                    type: PUBSUB.SUB,
                    source: socket.address,
                    subject: 'register',
                    info: 'Where is the broker?')
                .toJson())),
            InternetAddress('225.225.225.225'),
            port);
        socket.listen((RawSocketEvent event) {
          // recieve datagram from socket
          var datagram = socket.receive();
          // ensure datagram not null
          if (datagram is Datagram) {
            // pull data from datagram and convert into string
            final recieved = ProtocolInfo.fromJson(
                json.decode(AsciiCodec().decode(datagram.data)));
            // handle acknowledgement
            var size = socket.send(
                AsciiCodec().encode(json.encode(
                    ProtocolInfo.ack(socket.address, recieved.subject))),
                datagram.address,
                port);
            print(
                'Recieved: ${recieved.info} from ${datagram.address.address}:$port');
            print('sent ack of $size bytes');
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
