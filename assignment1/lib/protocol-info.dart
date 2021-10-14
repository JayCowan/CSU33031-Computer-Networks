import 'dart:io';

class ProtocolInfo {
  late PUBSUB type;
  late InternetAddress source;
  late String subject;
  late String info;

  ProtocolInfo(
      {required this.type,
      required this.source,
      required this.subject,
      required this.info});

  ProtocolInfo.fromJson(Map<String, dynamic> json) {
    var convertType = json['type'];
    if (convertType.trim().toLowerCase() == 'pub') {
      type = PUBSUB.PUB;
    } else if (convertType.trim().toLowerCase() == 'sub') {
      type = PUBSUB.SUB;
    } else if (convertType.trim().toLowerCase() == 'ack') {
      type = PUBSUB.ACK;
    } else {
      type = PUBSUB.ERROR;
    }
    source = InternetAddress(json['source']);
    subject = json['subject'];
    info = json['info'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (type == PUBSUB.PUB) {
      data['type'] = 'pub';
    } else if (type == PUBSUB.SUB) {
      data['type'] = 'sub';
    } else if (type == PUBSUB.ACK) {
      data['type'] = 'ack';
    } else {
      data['type'] = 'error';
    }
    data['source'] = source.address;
    data['subject'] = subject;
    data['info'] = info;
    return data;
  }
  static Map<String, dynamic> ack(InternetAddress source, String subject) {
    return ProtocolInfo(type: PUBSUB.ACK, subject: subject, source: source, info: '').toJson();
  }
}

enum PUBSUB { PUB, SUB, ACK, ERROR }
