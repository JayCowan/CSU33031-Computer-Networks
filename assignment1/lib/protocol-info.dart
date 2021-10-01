class ProtocolInfo {
  late PUBSUB type;
  late String info;

  ProtocolInfo({required String type, required this.info}) {
    if (type.trim().toLowerCase() == 'pub') {
      this.type = PUBSUB.PUB;
    } else if (type.trim().toLowerCase() == 'sub') {
      this.type = PUBSUB.SUB;
    } else if (type.trim().toLowerCase() == 'ack') {
      this.type = PUBSUB.ACK;
    } else {
      this.type = PUBSUB.ERROR;
    }
  }

  static Map<String, dynamic> ack() {
    return ProtocolInfo(type: 'ack', info: '').toJson();
  }

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
    info = json['info'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (type == PUBSUB.PUB) {
      data['type'] = 'pub';
    } else if (type == PUBSUB.SUB) {
      data['type'] = 'sub';
    } else if (type == PUBSUB.ACK) {
      data['type'] = 'ack';
    } else {
      data['type'] = 'error';
    }
    data['info'] = info;
    return data;
  }
}

enum PUBSUB { PUB, SUB, ACK, ERROR }
