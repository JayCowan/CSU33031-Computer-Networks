import 'dart:convert';
import 'dart:io';

import 'package:assignment1/protocol-info.dart';

class SubscriberProcess {
  Future<void> createSubscriberProcess(
      {required InternetAddress broker, required int port}) async {
    // Create datagram socket and bind to any ip address and the provided port
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, port)
        .then((RawDatagramSocket socket) {
      socket.send(
          Utf8Codec().encode(
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
              json.decode(Utf8Codec().decode(datagram.data)));
          // handle acknowledgement
          socket.send(Utf8Codec().encode(json.encode(ProtocolInfo.ack())),
              datagram.address, port);
          print('Recieved: ${recieved.info} from ${datagram.address.address}:$port');
        }
        //}
      });
    });
  }
}
