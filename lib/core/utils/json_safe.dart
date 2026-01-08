import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Safe JSON encoding utility that handles Firestore types
class JsonSafe {
  /// Sanitizes a value recursively to make it JSON-encodable
  static dynamic sanitize(Object? value) {
    if (value == null) return null;
    
    // Handle FieldValue (not encodable)
    if (value is FieldValue) {
      return '[FieldValue]';
    }
    
    // Handle Timestamp
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    
    // Handle DateTime
    if (value is DateTime) {
      return value.toIso8601String();
    }
    
    // Handle DocumentReference
    if (value is DocumentReference) {
      return value.path;
    }
    
    // Handle Map - sanitize recursively
    if (value is Map) {
      final sanitized = <String, dynamic>{};
      value.forEach((key, val) {
        sanitized[key.toString()] = sanitize(val);
      });
      return sanitized;
    }
    
    // Handle Iterable (List, Set, etc.)
    if (value is Iterable) {
      return value.map((item) => sanitize(item)).toList();
    }
    
    // Primitive types (int, double, String, bool) are already encodable
    return value;
  }
  
  /// Safely encode a value to JSON string
  static String encode(Object? value) {
    try {
      final sanitized = sanitize(value);
      return jsonEncode(sanitized);
    } catch (e) {
      // Last resort fallback
      return jsonEncode(value, toEncodable: (o) => o.toString());
    }
  }
}

