/*
* Author: James Cowan
* Student #: 19309917
*/

import 'dart:io';
import 'flow_table.dart';
import 'message.dart';

class Router {
  Map<String, Set<InternetAddress>> routingTable = {};
  FlowTable flowTable = FlowTable();

  Router();

  /// Starts the forwarding process and completes on a Future<void>
  Future<void> routerProcess() async {
    await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      51510,
      reuseAddress: false,
    ).then((RawDatagramSocket socket) {
      socket.listen((RawSocketEvent event) async {
        var dg = socket.receive();
        if (dg is Datagram) {
          Message message = Message.fromAsciiEncoded(dg.data);
          await _forward(dg, socket, message);
        }
      });
    });
  }

  /// Internal semi-recursive forwarding function
  Future<Message?> _forward(
      Datagram dg, RawDatagramSocket socket, Message message) async {
    switch (message.header.type) {
      case Type.networkId:
      // look to see if the location is on this network
        await InternetAddress.lookup(
                (message.header.value as NetworkId).location)
            .then(
          (value) => socket.send(dg.data, value.first, 51510),
        )
        // if the location is not on the network, look for the route
            .catchError((e) async {
          Iterable<FlowEntry> route = flowTable.flowTable.where((element) =>
              element.dest.toString() ==
              (message.header.value as NetworkId).toString());
          if (route.isEmpty) {
            // if no valid routes exist, request the flowentry from the controller
            await InternetAddress.lookup('controller')
                .then((value) => socket.send(
                    Message(
                            header: TLV(type: Type.combo, length: 2, value: {
                              TLV(
                                  type: Type.flow,
                                  length: (message.header.value as NetworkId)
                                      .toString()
                                      .length,
                                  value: message.header.value.toString()),
                              message.header
                            }),
                            payload: message.payload)
                        .toAsciiEncoded(),
                    value.first,
                    51510));
          } else if (route.length == 1) {
            // if we only have one route, and the egress is not null (which 
            //  means its not on the associated network), lookup the egress and 
            //  forward there
            if (route.first.egress != null) {
              await InternetAddress.lookup(route.first.egress!).then(
                (value) =>
                    socket.send(message.toAsciiEncoded(), value.first, 51510),
              );
            } else {
              // if the egress is null, meaning it should be on our network, 
              //  look up the location on the network and try to add it to our routing table
              await InternetAddress.lookup(
                      (message.header.value as NetworkId).location)
                  .then(
                (value) => routingTable.addAll(
                  {(message.header.value as NetworkId).location: value.toSet()},
                ),
              );
              // send the message to any addresses associated with the named 
              //  location
              routingTable.entries
                  .where((element) =>
                      element.key ==
                      (message.header.value as NetworkId).location)
                  .forEach(
                (element) {
                  for (var element in element.value) {
                    socket.send(message.toAsciiEncoded(), element, 51510);
                  }
                },
              );
            }
          } else {
            // no known way to forward the packet
            print(
                'Failed to forward packet to ${message.header.value} from ${dg.address.address}');
          }
          // though the value isnt used, the dart compiler requires a value of
          // the same type as the then() argument would return
          return 0;
        }, test: (e) => e is SocketException);
        break;
      case Type.combo:
        // when we recieve a combo (usually from the controller), check for 
        //  routing table updates and recursively handle them
        Set<TLV> updates = (message.header.value as Iterable<TLV>)
            .where((element) => element.type == Type.update)
            .toSet();
        for (TLV elem in updates) {
          await _forward(
              dg, socket, Message(header: elem, payload: message.payload));
        }
        // handle network ids by recurively calling forward, as this should now 
        //  be added to the routing table
        Set<TLV> netIds = (message.header.value as Iterable<TLV>)
            .where((element) => element.type == Type.networkId)
            .toSet();
        for (var elem in netIds) {
          await _forward(
              dg, socket, Message(header: elem, payload: message.payload));
        }
      break;
      case Type.flow:
        // the router doesnt handle flow requests
        print('Dropping flow packet from ${dg.address.address}');
        break;
      case Type.update:
        // add updates to the flow table
        flowTable.add(message.header.value as FlowEntry);
        break;
    }
  }
}
