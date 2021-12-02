import 'dart:collection';

import 'dart:convert';

import 'message.dart';

class FlowTable {
  HashSet<FlowEntry> flowTable = HashSet();

  FlowTable();
  /// Add a FlowEntry to the FlowTable if not already in the table
  void add(FlowEntry entry) {
    if (!flowTable.any((element) => element.toString() == entry.toString())) {
      flowTable.add(entry);
    }
  }
  /// Looks for a FlowEntry and if not there, throw StateError
  FlowEntry find(NetworkId dest, String ingress) {
    FlowEntry entry = flowTable.firstWhere(
        (element) => (element.dest.toString() == dest.toString()) && (element.ingress == ingress));
    return entry;
  }
}

class FlowEntry {
  late NetworkId dest;
  late String ingress;
  String? egress;

  FlowEntry({required this.dest, required this.ingress, this.egress});
  /// Decode a JSON object into its associated FlowEntry
  FlowEntry.fromJson(dynamic json) {
    json is Map<String, dynamic> ? json : json = jsonDecode(json);
    dest = NetworkId.fromString(json['dest']);
    ingress = json['ingress'];
    egress = json['egress'];
  }
  /// Returns the JSON object as a formatted String
  String toJsonString() {
    return jsonEncode(toJson());
  }
  /// Return a JSON encoded object from the FlowEntry
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['dest'] = dest.toString();
    data['ingress'] = ingress;
    data['egress'] = egress;
    return data;
  }

  @override
  String toString() {
    return 'dest: ${dest.toString()}, ingress: $ingress, egress: $egress';
  }
}
