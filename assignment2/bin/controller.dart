import 'dart:convert';
import 'dart:io';
import 'message.dart';

import 'flow_table.dart';

class Controller {
  FlowTable flowTable = FlowTable();
  Map<InternetAddress, String> locations = {};

  Controller();

  void _buildFlowTable() {
    Set<FlowEntry> entries = {
      FlowEntry(dest: 'reciever', ingress: 'startpoint', egress: 'router00'),
      FlowEntry(dest: 'reciever', ingress: 'router00', egress: 'router01'),
      FlowEntry(dest: 'reciever', ingress: 'router01', egress: 'router02'),
      FlowEntry(dest: 'reciever', ingress: 'router02', egress: 'endpoint'),
      FlowEntry(dest: 'reciever', ingress: 'endpoint')
    };
    for (FlowEntry entry in entries) {
      flowTable.add(entry);
      InternetAddress.lookup(entry.ingress).then(
        (value) => value.forEach(
          (element) {
            locations[element] = entry.ingress;
          },
        ),
        onError: (value) => print('couldn\'t find ${entry.ingress}'),
      );
    }
  }

  Future<void> control() async {
    try {
      await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        51510,
        reuseAddress: false,
      ).then((RawDatagramSocket socket) {
        socket.listen((RawSocketEvent event) {
          _buildFlowTable();
          if (event == RawSocketEvent.read) {
            var dg = socket.receive();
            if (dg is Datagram) {
              Message message = Message.fromAsciiEncoded(dg.data);
              switch (message.header.type) {
                case Type.networkId:
                  print(
                      'dropping network id packet from ${dg.address.address}');
                  break;
                case Type.combo:
                  try {
                    TLV lookup = (message.header.value as Set<TLV>)
                        .firstWhere((element) => element.type == Type.flow);
                    FlowEntry? entry = flowTable.find(
                        lookup.value as String, locations[dg.address]!);
                    if (entry is FlowEntry) {
                      (message.header.value as Set<TLV>).remove(lookup);
                      (message.header.value as Set<TLV>)
                          .add(TLV(type: Type.update, length: 1, value: entry));
                      TLV newHeader =
                          TLV.fromTLVs(tlvs: message.header.value as Set<TLV>);
                      socket.send(
                          Message(header: newHeader, payload: message.payload)
                              .toAsciiEncoded(),
                          dg.address,
                          51510);
                    } else {
                      print(
                          'Entry not in flow table, dropping packet from ${dg.address.address}');
                    }
                  } on StateError catch (e, s) {
                    print(
                        'Invalid combo sent to controller! Dropping packet from ${dg.address.address}');
                    stderr.addError(e, s);
                  }
                  break;
                case Type.flow:
                  FlowEntry? entry = flowTable.find(
                      (message.header.value as String), dg.address.address);
                  if (entry is FlowEntry) {
                    socket.send(
                        AsciiCodec().encode(jsonEncode(Message(
                                header: TLV(
                                    type: Type.update,
                                    length: 1,
                                    value: entry.toJson()),
                                payload: '')
                            .toJson())),
                        dg.address,
                        51510);
                    print(
                        'Sent update to ${dg.address.address} on update request for destination ${entry.dest}');
                  }
                  break;
                case Type.update:
                  print(
                      'only controller should send updates!\n    dropping update packet from ${dg.address.address}');
                  break;
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
}
