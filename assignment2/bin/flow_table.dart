import 'dart:collection';

import 'dart:convert';

import 'message.dart';

class FlowTable {
  HashSet<FlowEntry> flowTable = HashSet();

  FlowTable();

  void add(FlowEntry entry) {
    flowTable.add(entry);
  }

  FlowEntry? find(String dest, String ingress) {
    return flowTable.firstWhere(
        (element) => (element.dest == dest) && (element.ingress == ingress));
  }
}

class FlowEntry {
  late NetworkId dest;
  late String ingress;
  String? egress;

  FlowEntry({required this.dest, required this.ingress, this.egress});

  FlowEntry.fromJson(dynamic json) {
    json is Map<String, dynamic> ? json : json = jsonDecode(json);
    dest = NetworkId.fromString(json['dest']);
    ingress = json['ingress'];
    egress = json['egress'];
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['dest'] = dest.toString();
    data['ingress'] = ingress;
    data['egress'] = egress;
    return data;
  }
}
