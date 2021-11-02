import 'dart:convert';
import 'dart:io';

import 'package:assignment1/protocol-info.dart';

// A Broker protocol class to act as an intermediary between publishers and
//  subscribers, which accepts broadcast messages of publisher data and then,
//  decodes the message and publishes to any subscriber who is registered to
//  the given subject
class BrokerProcess {
  // The list of subscribers registered to this broker recorded as a map of
  //  their ip adress and a set containing their subjects
  Map<InternetAddress, Set<String>> subscribers =
      <InternetAddress, Set<String>>{};

  // The publishing protocol, which can accept subscribers, register them, and
  //  listen for publish requests, decode them and send them to associated
  //  subscribers
  Future<void> fetchProtocol({required int port}) async {
    try {
      // Bind to any ip on port provided
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, port,
              reuseAddress: true, reusePort: true)
          .then((RawDatagramSocket socket) {
        socket.broadcastEnabled = true;
        // Begin listening for pub and sub requests as well as ack
        socket.listen((RawSocketEvent event) {
          var datagram = socket.receive();
          if (datagram is Datagram && datagram.address.address != '127.0.0.1') {
            var info = ProtocolInfo.fromJson(
                json.decode(AsciiCodec().decode(datagram.data)));
            // Listen for pub requests
            if (info.type == PUBSUB.PUB) {
              print(
                  'Recieved message ${AsciiCodec().decode(datagram.data)} from ${datagram.address.address}:${datagram.port}');
              // Send ack back to publisher
              socket.send(
                  AsciiCodec().encode(json
                      .encode(ProtocolInfo.ack(socket.address, info.subject))),
                  datagram.address,
                  datagram.port);
              // Convert recieved datagram to a forward message and send to
              //  subscribers registered to the message's subject
              var dg = ProtocolInfo.fromJson(
                  json.decode(AsciiCodec().decode(datagram.data)));
              subscribers.forEach((key, values) {
                dg.type = PUBSUB.FORWARD;
                dg.source = datagram.address;
                if (values.contains(dg.subject)) {
                  socket.send(
                      AsciiCodec().encode(json.encode(dg.toJson())), key, port);
                  print(
                      'Sent subject:${dg.subject}, message:${dg.info} to ${key.address}:${datagram.port}');
                }
              });
            } else if (info.type == PUBSUB.SUB && info.subject == 'register') {
              // Catch any registry requests and update the subscribers map
              print(
                  'register ${datagram.address.address} for subjects ${info.info.substring(1, info.info.length - 1)}');
              subscribers.update(datagram.address, (value) {
                //
                value.addAll(
                    info.info.substring(1, info.info.length - 1).split(', '));
                value.forEach((element) {
                  print(element.toString());
                });
                return value; // TODO: Check if needed
              },
                  ifAbsent: () => info.info
                      .substring(1, info.info.length - 1)
                      .split(', ')
                      .toSet());
              // send ack to subscriber
              socket.send(
                  AsciiCodec().encode(json.encode(
                      ProtocolInfo.ack(datagram.address, info.subject))),
                  datagram.address,
                  port);
            } else if (info.type == PUBSUB.ACK) {
              print(
                  'Ack: ${datagram.address.address}, Subject: ${info.subject}');
            } else if (info.type == PUBSUB.ERROR) {
              print('Unknown action in pubsub process with data ${info.info}');
            }
          }
        });
      });
    } on SocketException catch (e, s) {
      // catch any socket errors and add to std error
      stderr.addError(e, s);
      return;
    } catch (e, s) {
      // add other errors to stderror
      stderr.addError(e, s);
    }
  }
}
