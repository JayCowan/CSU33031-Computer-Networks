import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'flow_table.dart';

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

  /* TLV.fromIdentifier({required Identifier identifier}) {
    type = Type.identify;
    length = 1;
    value = identifier;
  } */

  TLV.fromNetworkId(NetworkId networkId) {
    type = Type.networkId;
    length = networkId.toString().length;
    value = networkId;
  }

  TLV.fromTLVs({required Iterable<TLV> tlvs}) {
    type = Type.combo;
    length = tlvs.length;
    value = tlvs.toSet();
  }

  TLV.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {

      /// assume that this is Type.networkId
      case 0:
        type = Type.networkId;
        length = json['len'];
        value = NetworkId.fromString(json['val']);
        break;

      /// assume that this is Type.combo
      case 1:
        type = Type.combo;
        length = json['len'];
        Iterable vals = jsonDecode(json['val']);
        value = <TLV>{};
        for (var val in vals) {
          (value as Set<TLV>).add(TLV.fromJson(val));
        }
        break;

      /// assume that this is Type.flow
      case 2:
        type = Type.flow;
        length = json['len'];
        value = json['val'];
        break;

      /// assume that this is Type.update
      case 3:
        type = Type.update;
        length = json['len'];
        value = FlowEntry.fromJson(json['val']);
        break;

      /* /// assume that this is Type.identify
      case 4:
        type = Type.identify;
        length = 1;
        value = Identifier.values[json['val']];
        break; */
      default:
        throw ArgumentError.value(
            json['type'], 'type', 'Invalid value when trying to parse json');
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    switch (type) {
      case Type.networkId:
        data['val'] = value.toString();
        data['len'] = value.toString().length;
        break;
      case Type.combo:
        data['val'] = jsonEncode((value as Iterable<TLV>).toList());
        data['len'] = (value as Set<TLV>).length;
        break;
      case Type.flow:
        data['val'] = value;
        data['len'] = (value as String).length;
        break;
      case Type.update:
        data['val'] = jsonEncode(value);
        data['len'] = 1;
        break;
      /* case Type.identify:
        data['val'] = jsonEncode(
            value is Identifier ? (value as Identifier).index : 'error');
        data['len'] = 1;
        break; */
    }
    data['type'] = type.index;
    return data;
  }
}

enum Type { networkId, combo, flow, update }

//enum Identifier { forwarder, router, controller, element }

/// The Network Id for the purpose of routing messages to its destination
class NetworkId {
  /// The network to wich the destination belongs to ex: router02
  late String network;

  /// The location/computer within the network to which the destination belongs ex: John's PC
  late String location;

  /// The element/application within the location computer to deliver the message to ex: Chrome
  late String element;

  NetworkId(
      {required this.network, required this.location, required this.element});

  NetworkId.fromString(String networkId) {
    List<String> elems = networkId.split('.');
    network = elems[0];
    location = elems[1];
    element = elems[2];
  }

  @override
  String toString() {
    return '$network.$location.$element';
  }
}
