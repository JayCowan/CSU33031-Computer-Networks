import 'dart:convert';
import 'dart:io';

import 'package:assignment1/protocol-info.dart';

class SubscriberProcess {
  Future<void> createSubscriberProcess(
      {required InternetAddress broker, required int port}) async {
    // Create datagram socket and bind to any ip address and the provided port
    try {
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, port,
              reuseAddress: true, reusePort: true)
          .then((RawDatagramSocket socket) {
        socket.broadcastEnabled = true;
        socket.send(
            AsciiCodec().encode(
                json.encode(ProtocolInfo(type: 'sub', info: '').toJson())),
            broker,
            port);
        socket.listen((RawSocketEvent event) {
          //if (event == RawSocketEvent.read) {
          // recieve datagram from socket
          var datagram = socket.receive();
          // ensure datagram not null
          if (datagram is Datagram) {
            // pull data from datagram and convert into string
            final recieved = ProtocolInfo.fromJson(
                json.decode(AsciiCodec().decode(datagram.data)));
            // handle acknowledgement
            int size = socket.send(
                AsciiCodec().encode(json.encode(ProtocolInfo.ack())),
                datagram.address,
                port);
            print(
                'Recieved: ${recieved.info} from ${datagram.address.address}:$port');
            print('sent ack of $size bytes');
          }
          //}
        });
      });
    } on SocketException catch (e) {
      stderr.addError(e);
    }
  }
}
