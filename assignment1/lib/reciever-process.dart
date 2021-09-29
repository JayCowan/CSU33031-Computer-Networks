import 'dart:convert';
import 'dart:io';

class RecieverProcess {
  static Future<void> createReacieverProcess({required int port}) async {
    // Create datagram socket and bind to any ip address and the provided port
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, port)
        .then((RawDatagramSocket socket) {
      print('Now listening from ${socket.address.address}:$port');
      socket.listen((RawSocketEvent event) {
        //if (event == RawSocketEvent.read) {
        // recieve datagram from socket
        var datagram = socket.receive();
        // ensure datagram not null
        if (datagram is Datagram) {
          // pull data from datagram and convert into string
          final recieved = String.fromCharCodes(datagram.data);
          // handle ping acknowledgement
          if (recieved == 'ping') {
            socket.send(
                Utf8Codec().encode('ack: ping'), datagram.address, port);
          }
          print('Recieved: $recieved from ${datagram.address.address}:$port');
        }
        //}
      });
    });
  }
}
