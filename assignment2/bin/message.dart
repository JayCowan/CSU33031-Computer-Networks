import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

class Message {
  late TLV header;
  late String payload;

  Message({required this.header, required this.payload});

  Message.fromAsciiEncoded(Uint8List data) {
    var json = jsonDecode(AsciiCodec().decode(data));
    header = TLV.fromJson(json['header']);
    payload = json['payload'];
  }

  Uint8List toAsciiEncoded() {
    return AsciiCodec().encode(json.encode(toJson()));
  }

  Map<String, dynamic> toJson() {
    StringBuffer buffer = StringBuffer();
    buffer.writeAll([
      '{ ',
      '"header": ',
      '${json.encode(header.toJson())},',
      '"payload": ',
      '"$payload"',
      '}'
    ]);
    return json.decode(buffer.toString());
  }
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
        value = TLV.fromJson(jsonDecode(json['val']));
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
        data['val'] = jsonEncode(value as Iterable);
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
