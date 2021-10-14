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
            if (info.type == PUBSUB.PUB) {
              print(
                  'Recieved message ${AsciiCodec().decode(datagram.data)} from ${datagram.address.address}:${datagram.port}');
              socket.send(
                  AsciiCodec().encode(json
                      .encode(ProtocolInfo.ack(socket.address, info.subject))),
                  datagram.address,
                  datagram.port);
              subscribers.forEach((key, values) {
                if (values.contains(ProtocolInfo.fromJson(
                        json.decode(AsciiCodec().decode(datagram.data)))
                    .subject)) {
                  socket.send(datagram.data, key, port);
                }
              });
            } else if (info.type == PUBSUB.SUB) {
              subscribers.update(info.source, (value) {
                value.add(info.subject);
                return value;
              }, ifAbsent: () => <String>{info.subject});
              socket.send(
                  AsciiCodec().encode(json
                      .encode(ProtocolInfo.ack(socket.address, info.subject))),
                  datagram.address,
                  port);
            } else if (info.type == PUBSUB.ACK) {
              print('Ack: ${datagram.address.address}');
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
