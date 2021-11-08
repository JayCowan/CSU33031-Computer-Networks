import 'dart:io';
import 'message.dart';

class Element {
  Future<void> recieve() async {
    try {
      await RawDatagramSocket.bind('router', 51510)
          .then((RawDatagramSocket socket) {
        socket.listen((RawSocketEvent event) {
          while (exitCode == 0) {
            if (event == RawSocketEvent.read) {
              var dg = socket.receive();
              if (dg is Datagram) {
                Message message = Message.fromAsciiEncoded(dg.data);
                stdout.write(message.payload);
                print(message.payload);
              }
            }
          }
        });
      });
    } on Exception catch (e, s) {
      exitCode = 2;
      stderr.addError(e, s);
    }
  }

  Future<void> send() async {
    try {
      RawDatagramSocket.bind('router', 51510).then((RawDatagramSocket socket) {
        while (exitCode == 0) {
          InternetAddress.lookup('router').then((value) {
            stdout.writeAll(value);
            print(value);
            for (var element in value) {
              socket.send(
                  Message(
                          header: TLV(
                              type: Type.networkId, length: 4, value: 'test'),
                          payload: 'hello')
                      .toAsciiEncoded(),
                  element,
                  51510);
              print('sent');
              stdout.write('sent');
            }
          });
        }
      });
    } catch (e, s) {
      exitCode = 2;
      stderr.addError(e, s);
    }
  }
}
