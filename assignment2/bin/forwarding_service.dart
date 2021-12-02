import 'dart:io';

import 'message.dart';

class ForwardingService {
  ForwardingService();

  Future<void> forwardingProcess() async {
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, 51510)
        .then((RawDatagramSocket socket) {
      socket.listen((RawSocketEvent event) async {
        var dg = socket.receive();
        if (dg is Datagram) {
          Message message = Message.fromAsciiEncoded(dg.data);
          await _forward(dg, message, socket);
        }
      });
    });
  }

  Future<void> _forward(
      Datagram dg, Message message, RawDatagramSocket socket) async {
    switch (message.header.type) {
      case Type.networkId:
        InternetAddress.lookup((message.header.value as NetworkId).element)
            .then(
          (value) {
            // is an element in the network
            socket.send(dg.data, value.first, 51510);
          },
        ).catchError((e) {
          print(
              'couldn\'t find ${(message.header.value as NetworkId).element}');
          InternetAddress.lookup('router').then(
            (value) => socket.send(dg.data, value.first, 51510),
          );
        }, test: (e) => e is SocketException);
        break;
      case Type.combo:
        Set<TLV> tlvs = (message.header.value as Iterable<TLV>).toSet();
        for (TLV tlv in tlvs) {
          Message newMessage = Message(header: tlv, payload: message.payload);
          await _forward(dg, newMessage, socket);
        }
        break;
      case Type.flow:
        print(
            'Only the controller should recieve flow packets! Dropping packet...');
        break;
      case Type.update:
        print('dropping update packet from ${dg.address.address}');
        break;
    }
  }
}
