import 'package:cloud_firestore/cloud_firestore.dart';

/// Unified Firestore type conversion helpers
/// Use these for ALL Firestore reads/writes to prevent type mismatches

/// Safely read an int value from Firestore dynamic data
/// Handles: int, String (parseable), double (converts to int)
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

/// Safely read a boolean value from Firestore dynamic data
/// Handles: bool, int (0/1), String ("true"/"1"/"false"/"0")
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

/// Safely read a DateTime from Firestore dynamic data
/// Handles: Timestamp, int (milliseconds), String (ISO format)
DateTime? readDate(dynamic v) {
  if (v == null) return null;

  // Handle Firestore Timestamp
  if (v is Timestamp) {
    return v.toDate();
  }

  // Handle int (milliseconds since epoch)
  if (v is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(v);
    } catch (e) {
      return null;
    }
  }

  // Handle String (ISO format)
  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (e) {
      return null;
    }
  }

  // Handle DateTime (already parsed)
  if (v is DateTime) {
    return v;
  }

  return null;
}

/// Safely read a String value from Firestore dynamic data
String? readString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

/// Safely read a double value from Firestore dynamic data
double? readDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) {
    return double.tryParse(v);
  }
  return null;
}
