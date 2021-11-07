import 'dart:convert';

class Message {
  TLV header;
  String payload;

  Message({required this.header, required this.payload});
}

class TLV {
  late Type type;
  late int length;
  late Object value;
  TLV({required this.type, required this.length, required this.value});

  TLV.fromTLVs({required Iterable<TLV> tlvs}) {
    type = Type.combo;
    length = tlvs.length;
    value = tlvs;
  }

  TLV.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {

      /// assume that this is Type.networkId
      case 0:
        type = Type.networkId;
        length = json['len'];
        value = json['val'] as String;
        break;

      /// assume that this is Type.combo
      case 1:
        type = Type.combo;
        length = json['len'];
        value = TLV.fromJson(json['val']);
        break;
      default:
        throw ArgumentError.value(
            json['type'], 'type', 'Invalid value when trying to parse json');
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    switch (type) {
      case Type.networkId:
        data['val'] = value is String ? value : value.toString();
        data['len'] = (value as String).length;
        break;
      case Type.combo:
        data['val'] = jsonEncode(value);
        data['len'] = (value as Iterable).length;
        break;
    }
    data['type'] = type.index;
    return data;
  }
}

enum Type {
  networkId,
  combo,
}
