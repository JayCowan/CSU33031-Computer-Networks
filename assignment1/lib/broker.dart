import 'dart:convert';
import 'dart:io';

import 'package:assignment1/protocol-info.dart';

class BrokerProcess {
  Map<InternetAddress, Set<String>> subscribers =
      <InternetAddress, Set<String>>{};
  //List<InternetAddress> publishers = <InternetAddress>[];

  static Future<void> publishProtocol(String message, int port) async {
    await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
        .then((RawDatagramSocket socket) {
      print('Now publishing from ${socket.address.address}:$port');
      socket.broadcastEnabled = true;
      if (socket.send(
              AsciiCodec().encode(message), InternetAddress('broker'), port) !=
          0) {
        print('sent: $message to address :$port');
      } else {
        throw SocketException('failed to send message',
            address: InternetAddress.anyIPv4, port: port);
      }
    });
  }

  Future<void> fetchProtocol({required int port}) async {
    try {
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, 50001,
              reuseAddress: true, reusePort: true)
          .then((RawDatagramSocket socket) {
        socket.broadcastEnabled = true;
        socket.listen((RawSocketEvent event) {
          var datagram = socket.receive();
          if (datagram is Datagram) {
            var info = ProtocolInfo.fromJson(
                json.decode(AsciiCodec().decode(datagram.data)));
            if (info.type == PUBSUB.PUB &&
                datagram.address.address != '127.0.0.1') {
              print(
                  'Recieved message ${AsciiCodec().decode(datagram.data)} from ${datagram.address.address}:${datagram.port}');
              socket.send(
                  AsciiCodec().encode(json
                      .encode(ProtocolInfo.ack(socket.address, info.subject))),
                  datagram.address,
                  datagram.port);
              // print(AsciiCodec().decode(datagram.data));
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
              print(
                  'register ${datagram.address.address} for subjects ${info.info.substring(1, info.info.length - 1)}');
              subscribers.update(datagram.address, (value) {
                value.addAll(
                    info.info.substring(1, info.info.length - 1).split(', '));
                value.forEach((element) {
                  print(element.toString());
                });
                return value;
              },
                  ifAbsent: () => info.info
                      .substring(1, info.info.length - 1)
                      .split(', ')
                      .toSet());
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
      stderr.addError(e, s);
      return;
    } catch (e, s) {
      stderr.addError(e, s);
    }
  }
}
