import 'dart:convert';
import 'dart:io';

class SenderProcess {
  static Future<void> sendStringMessage(String message, int port) async {
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
        .then((RawDatagramSocket socket) {
      print('Now publishing from ${socket.address.address}:$port');
      socket.broadcastEnabled = true;
      if (socket.send(Utf8Codec().encode(message), InternetAddress.loopbackIPv4,
              port) !=
          0) {
        print(
            'sent: $message to address ${InternetAddress.loopbackIPv4.address}:$port');
      } else {
        throw SocketException('failed to send message',
            address: InternetAddress.anyIPv4, port: port);
      }
    });
  }
}
