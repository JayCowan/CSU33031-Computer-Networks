import 'dart:io';

// Encoding class for the protocol, to group type, subject, info, and source 
//  together
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

  // JSON based constructor to decode from source
  ProtocolInfo.fromJson(Map<String, dynamic> json) {
    var convertType = json['type'];
    if (convertType.trim().toLowerCase() == 'pub') {
      type = PUBSUB.PUB;
    } else if (convertType.trim().toLowerCase() == 'sub') {
      type = PUBSUB.SUB;
    } else if (convertType.trim().toLowerCase() == 'ack') {
      type = PUBSUB.ACK;
    } else if (convertType.trim().toLowerCase() == 'forward') {
      type = PUBSUB.FORWARD;
    } else {
      type = PUBSUB.ERROR;
    }
    source = InternetAddress(json['source']);
    subject = json['subject'];
    info = json['info'];
  }

  // Export the protocol info to json so it can be sent properly
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (type == PUBSUB.PUB) {
      data['type'] = 'pub';
    } else if (type == PUBSUB.SUB) {
      data['type'] = 'sub';
    } else if (type == PUBSUB.ACK) {
      data['type'] = 'ack';
    } else if (type == PUBSUB.FORWARD) {
      data['type'] = 'forward';
    } else {
      data['type'] = 'error';
    }
    data['source'] = source.address;
    data['subject'] = subject;
    data['info'] = info;
    return data;
  }

  // Standardized ack function to be used only for encoding acknowledgements
  static Map<String, dynamic> ack(InternetAddress source, String subject) {
    return ProtocolInfo(
            type: PUBSUB.ACK, subject: subject, source: source, info: '')
        .toJson();
  }
}

// Enum for classifying the type of message
enum PUBSUB { PUB, SUB, FORWARD, ACK, ERROR }
