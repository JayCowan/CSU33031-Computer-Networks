import 'dart:convert';
import 'dart:io';

class SenderProcess {
  static Future<void> sendStringMessage(String message, int port) async {
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, port)
        .then((RawDatagramSocket socket) {
      if (socket.send(Utf8Codec().encode(message), InternetAddress.anyIPv4,
              port) !=
          0) {
        print('sent: $message to address ${socket.address.address}:$port');
      } else {
        throw SocketException('failed to send message',
            address: InternetAddress.anyIPv4, port: port);
      }
    });
  }
}
