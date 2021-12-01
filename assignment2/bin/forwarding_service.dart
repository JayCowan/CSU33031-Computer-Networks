import 'dart:convert';
import 'dart:io';

import 'flow_table.dart';
import 'message.dart';

class ForwardingService {
  //FlowTable flowTable = FlowTable();

  ForwardingService();

  Future<void> forwardingProcess() async {
    // maybe use loopback if router is host?
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, 51510)
        .then((RawDatagramSocket socket) {
      /* socket.broadcastEnabled = true;
      socket.send(
          Message(
                  header: TLV.fromIdentifier(identifier: Identifier.forwarder),
                  payload: '')
              .toAsciiEncoded(),
          InternetAddress('255.255.255.255'),
          51510); */
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
        String elem = (message.header.value as NetworkId).element;
        print('looking for $elem');
        InternetAddress.lookup((message.header.value as NetworkId).element)
            .then(
          (value) {
            print(value.first.address);
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

        /* Iterable<FlowEntry> route = flowTable.flowTable.where(
            (element) => element.dest == (message.header.value as String));
        if (route.isEmpty) {
          InternetAddress.lookup('controller').then((value) => socket.send(
              Message(
                      header: TLV(type: Type.combo, length: 2, value: {
                        TLV(
                            type: Type.flow,
                            length: (message.header.value as String).length,
                            value: message.header.value),
                        message.header
                      }),
                      payload: message.payload)
                  .toAsciiEncoded(),
              value.first,
              51510));
        } else if (route.first.egress is String) {
          InternetAddress.lookup(route.first.egress!).then((value) =>
              socket.send(message.toAsciiEncoded(), value.first, 51510));
        } else if (route.first.egress == null) {
          InternetAddress.lookup(route.first.dest).then(
            (value) => socket.send(dg.data, value.first, 51510),
          );
        } else {
          print('Dropping packet from ${dg.address.address}');
        } */
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
        /* flowTable.add(
          message.header.value is FlowEntry
              ? message.header.value as FlowEntry
              : FlowEntry.fromJson(
                  message.header.value as Map<String, dynamic>),
        ); */
        print('dropping update packet from ${dg.address.address}');
        break;
      /* case Type.identify:
        switch ((message.header.value as Identifier)) {
          case Identifier.router:
            break;
          default:
            print(message.toString());
            break;
        }
        break; */
    }
  }
}
