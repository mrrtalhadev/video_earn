import 'package:cloud_firestore/cloud_firestore.dart';

/// Lenient readers for Firestore maps (missing/mistyped fields fall back).
extension FsMapRead on Map<String, dynamic> {
  String str(String key, [String fallback = '']) {
    final v = this[key];
    return v is String ? v : fallback;
  }

  String? strOrNull(String key) {
    final v = this[key];
    return (v is String && v.isNotEmpty) ? v : null;
  }

  int integer(String key, [int fallback = 0]) {
    final v = this[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  bool boolean(String key, [bool fallback = false]) {
    final v = this[key];
    return v is bool ? v : fallback;
  }

  DateTime? date(String key) {
    final v = this[key];
    return v is Timestamp ? v.toDate() : null;
  }

  Map<String, dynamic> subMap(String key) {
    final v = this[key];
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  }
}

typedef Doc = DocumentSnapshot<Map<String, dynamic>>;
