import 'dart:io';

import 'dart:typed_data';

class SenderProcess {
  final int RECV_PORT = 12345;
  final int MTU = 1500;

  late Datagram packet;
  late RawDatagramSocket socket;
  late InternetAddress address;
  late int port;

  late ByteBuffer buffer;
  
}
