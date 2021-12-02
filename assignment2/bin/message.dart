import 'dart:convert';

import 'dart:typed_data';

import 'flow_table.dart';

class Message {
  late TLV header;
  late String payload;

  Message({required this.header, required this.payload});

  /// Takes the ascii encoded data (usually from Datagram.data) and decodees it
  /// into an Instance of Message
  Message.fromAsciiEncoded(Uint8List data) {
    var json = jsonDecode(AsciiCodec().decode(data));
    header = TLV.fromJson(json['header']);
    payload = json['payload'];
  }

  /// Encode the Message into ASCII (usually used to send as Datagram.data)
  Uint8List toAsciiEncoded() {
    return AsciiCodec().encode(json.encode(toJson()));
  }

  /// Export the message to a json format
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

/// A class to handle the headers of messages, taking an enumerated type, a
/// length of either the content or number of elements, and an object, usually a
/// string encoding of the network id, flow entry or a set of other TLVs
class TLV {
  late Type type;
  late int length;
  late Object value;
  TLV({required this.type, required this.length, required this.value});

  /// Build a networkId enumerated TLV
  TLV.fromNetworkId(NetworkId networkId) {
    type = Type.networkId;
    length = networkId.toString().length;
    value = networkId;
  }

  /// Create a combo enumerated TLV from a Set of TLVs
  TLV.fromTLVs({required Iterable<TLV> tlvs}) {
    type = Type.combo;
    length = tlvs.length;
    value = tlvs.toSet();
  }

  /// Decode a TLV from a JSON object
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

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  /// Returns a JSON encoded object from the TLV
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
    }
    data['type'] = type.index;
    return data;
  }
}

/// Type enumeration for handling TLVs
enum Type { networkId, combo, flow, update }

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

  /// Build a NetworkId from a properly formatted string, like
  /// 'router.location.element'
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
