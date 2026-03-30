library;

bool readBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) {
    final lower = v.toLowerCase().trim();
    return lower == 'true' || lower == '1';
  }
  return false;
}

int? readInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}

double? readDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String? readString(dynamic v) {
  if (v is String) return v;
  if (v == null) return null;
  return v.toString();
}
