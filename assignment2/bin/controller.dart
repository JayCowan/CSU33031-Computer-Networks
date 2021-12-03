import 'dart:convert';
import 'dart:io';
import 'message.dart';

import 'flow_table.dart';

class Controller {
  // the base flow table to use
  FlowTable flowTable = FlowTable();
  // this lets us associate named tables with addresses to match named
  // requestors addresses with named ingress addresses
  Map<InternetAddress, String> locations = {};

  Controller();

  /// Manually construct the flow table
  void _buildFlowTable() {
    Set<FlowEntry> entries = {
      FlowEntry(
        dest: NetworkId.fromString('router02.endpoint.reciever'),
        ingress: 'startpoint',
        egress: 'router00',
      ),
      FlowEntry(
        dest: NetworkId.fromString('router02.endpoint.reciever'),
        ingress: 'router00',
        egress: 'router01',
      ),
      FlowEntry(
        dest: NetworkId.fromString('router02.endpoint.reciever'),
        ingress: 'router01',
        egress: 'router02',
      ),
      FlowEntry(
        dest: NetworkId.fromString('router02.endpoint.reciever'),
        ingress: 'router02',
        egress: 'endpoint',
      ),
      FlowEntry(
        dest: NetworkId.fromString('router02.endpoint.reciever'),
        ingress: 'endpoint',
      )
    };
    // build locations to associate the address with the named element on the network
    for (FlowEntry entry in entries) {
      flowTable.add(entry);
      InternetAddress.lookup(entry.ingress).then(
        (value) {
          // add each lookup result to the locations table
          for (var element in value) {
            locations[element] = entry.ingress;
          }
        },
        onError: (value) => print('couldn\'t find ${entry.ingress}'),
      );
    }
  }

  /// Begins the controller process and completes on a Future<void>
  Future<void> control() async {
    try {
      await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        51510,
        reuseAddress: false,
      ).then((RawDatagramSocket socket) {
        // build the flow table before listening
        _buildFlowTable();
        socket.listen((RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            var dg = socket.receive();
            if (dg is Datagram) {
              Message message = Message.fromAsciiEncoded(dg.data);
              switch (message.header.type) {
                case Type.networkId:
                  // controllers dont need networkIds
                  break;
                case Type.combo:
                  try {
                    // look for flow requests in header, otherwise throw a stateerror
                    TLV lookup = (message.header.value as Set<TLV>)
                        .firstWhere((element) => element.type == Type.flow);
                    // look for a flowentry matching the request in the header
                    FlowEntry? entry = flowTable.find(
                        NetworkId.fromString(lookup.value as String),
                        locations[dg.address]!);
                    if (entry is FlowEntry) {
                      // clean the header for the returned message
                      (message.header.value as Set<TLV>).remove(lookup);
                      // add the update to the return header
                      (message.header.value as Set<TLV>)
                          .add(TLV(type: Type.update, length: 1, value: entry));
                      TLV newHeader =
                          TLV.fromTLVs(tlvs: message.header.value as Set<TLV>);
                      // now send the update with the original message
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
                  // when you have just a flow request, find the address
                  FlowEntry? entry = flowTable.find(
                      (message.header.value as NetworkId), dg.address.address);
                  // if found
                  if (entry is FlowEntry) {
                    // send the entry to the requesting network location
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
                  // controller shouldnt recieve updates
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
