import 'dart:io';
import 'message.dart';

class Element {
  Element();

  Future<void> recieve() async {
    try {
      await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        51510,
        reuseAddress: false,
      ).then((RawDatagramSocket socket) {
        socket.listen((RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            var dg = socket.receive();
            if (dg is Datagram) {
              Message message = Message.fromAsciiEncoded(dg.data);
              print('recieved: ${message.payload}');
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
      await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        51510,
        reuseAddress: false,
      ).then((RawDatagramSocket socket) async {
        await InternetAddress.lookup('router').then((value) {
          stdout.writeAll(value);
          socket.send(
              Message(
                      header: TLV(
                        type: Type.networkId,
                        length: 8,
                        value: 'endpoint',
                      ),
                      payload: 'hello')
                  .toAsciiEncoded(),
              value.first,
              51510);
        }).then((value) => socket.close());
      });
    } catch (e, s) {
      exitCode = 2;
      stderr.addError(e, s);
    }
  }
}
