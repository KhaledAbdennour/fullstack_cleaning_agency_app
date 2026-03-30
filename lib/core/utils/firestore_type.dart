import 'package:cloud_firestore/cloud_firestore.dart';

int? readInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) {
    final parsed = int.tryParse(v);
    if (parsed != null) return parsed;
  }
  return null;
}

bool readBool(dynamic v, {bool defaultValue = false}) {
  if (v == null) return defaultValue;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) {
    final lower = v.toLowerCase().trim();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return defaultValue;
}

DateTime? readDate(dynamic v) {
  if (v == null) return null;

  if (v is Timestamp) {
    return v.toDate();
  }

  if (v is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(v);
    } catch (e) {
      return null;
    }
  }

  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (e) {
      return null;
    }
  }

  if (v is DateTime) {
    return v;
  }

  return null;
}

String? readString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

double? readDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) {
    return double.tryParse(v);
  }
  return null;
}
