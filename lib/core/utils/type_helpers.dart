/// Safe type conversion helpers for Firestore dynamic data

/// Safely read a boolean value from Firestore dynamic data
/// Handles: bool, int (0/1), String ("true"/"1"/"false"/"0")
bool readBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) {
    final lower = v.toLowerCase().trim();
    return lower == 'true' || lower == '1';
  }
  return false;
}

/// Safely read an int value from Firestore dynamic data
/// Handles: int, String (parseable)
int? readInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}

/// Safely read a double value from Firestore dynamic data
double? readDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// Safely read a String value from Firestore dynamic data
String? readString(dynamic v) {
  if (v is String) return v;
  if (v == null) return null;
  return v.toString();
}

