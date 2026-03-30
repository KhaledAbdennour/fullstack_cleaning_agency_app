import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class JsonSafe {
  static dynamic sanitize(Object? value) {
    if (value == null) return null;

    if (value is FieldValue) {
      return '[FieldValue]';
    }

    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is DocumentReference) {
      return value.path;
    }

    if (value is Map) {
      final sanitized = <String, dynamic>{};
      value.forEach((key, val) {
        sanitized[key.toString()] = sanitize(val);
      });
      return sanitized;
    }

    if (value is Iterable) {
      return value.map((item) => sanitize(item)).toList();
    }

    return value;
  }

  static String encode(Object? value) {
    try {
      final sanitized = sanitize(value);
      return jsonEncode(sanitized);
    } catch (e) {
      return jsonEncode(value, toEncodable: (o) => o.toString());
    }
  }
}
