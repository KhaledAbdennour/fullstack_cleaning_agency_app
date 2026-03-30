import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mob_dev_project/core/utils/firestore_type.dart';

void main() {
  group('readInt', () {
    test('returns int when value is int', () {
      expect(readInt(42), equals(42));
      expect(readInt(0), equals(0));
      expect(readInt(-10), equals(-10));
    });

    test('returns int when value is double', () {
      expect(readInt(42.7), equals(42));
      expect(readInt(0.0), equals(0));
      expect(readInt(-10.9), equals(-10));
    });

    test('returns int when value is parseable string', () {
      expect(readInt('42'), equals(42));
      expect(readInt('0'), equals(0));
      expect(readInt('-10'), equals(-10));
    });

    test('returns null when value is null', () {
      expect(readInt(null), isNull);
    });

    test('returns null when value is non-parseable string', () {
      expect(readInt('not a number'), isNull);
      expect(readInt('abc123'), isNull);
    });
  });

  group('readBool', () {
    test('returns bool when value is bool', () {
      expect(readBool(true), isTrue);
      expect(readBool(false), isFalse);
    });

    test('returns bool when value is int', () {
      expect(readBool(1), isTrue);
      expect(readBool(0), isFalse);
    });

    test('returns bool when value is string', () {
      expect(readBool('true'), isTrue);
      expect(readBool('1'), isTrue);
      expect(readBool('false'), isFalse);
      expect(readBool('0'), isFalse);
    });

    test('returns defaultValue when value is null', () {
      expect(readBool(null), isFalse);
      expect(readBool(null, defaultValue: true), isTrue);
    });

    test('returns defaultValue for invalid string', () {
      expect(readBool('invalid'), isFalse);
      expect(readBool('maybe', defaultValue: true), isTrue);
    });
  });

  group('readDate', () {
    test('returns DateTime when value is Timestamp', () {
      final timestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30));
      final result = readDate(timestamp);
      expect(result, isNotNull);
      expect(result!.year, equals(2024));
      expect(result.month, equals(1));
      expect(result.day, equals(15));
    });

    test('returns DateTime when value is int (milliseconds)', () {
      final ms = DateTime(2024, 1, 15).millisecondsSinceEpoch;
      final result = readDate(ms);
      expect(result, isNotNull);
      expect(result!.year, equals(2024));
      expect(result.month, equals(1));
      expect(result.day, equals(15));
    });

    test('returns DateTime when value is ISO string', () {
      final iso = '2024-01-15T10:30:00Z';
      final result = readDate(iso);
      expect(result, isNotNull);
      expect(result!.year, equals(2024));
    });

    test('returns DateTime when value is already DateTime', () {
      final dt = DateTime(2024, 1, 15);
      final result = readDate(dt);
      expect(result, equals(dt));
    });

    test('returns null when value is null', () {
      expect(readDate(null), isNull);
    });

    test('returns null when value is invalid', () {
      expect(readDate('not a date'), isNull);
      expect(readDate('invalid-format'), isNull);
    });
  });

  group('readString', () {
    test('returns string when value is string', () {
      expect(readString('hello'), equals('hello'));
      expect(readString(''), equals(''));
    });

    test('returns string representation when value is not string', () {
      expect(readString(42), equals('42'));
      expect(readString(true), equals('true'));
    });

    test('returns null when value is null', () {
      expect(readString(null), isNull);
    });
  });

  group('readDouble', () {
    test('returns double when value is double', () {
      expect(readDouble(42.5), equals(42.5));
      expect(readDouble(0.0), equals(0.0));
    });

    test('returns double when value is int', () {
      expect(readDouble(42), equals(42.0));
      expect(readDouble(0), equals(0.0));
    });

    test('returns double when value is parseable string', () {
      expect(readDouble('42.5'), equals(42.5));
      expect(readDouble('0'), equals(0.0));
      expect(readDouble('-10.3'), equals(-10.3));
    });

    test('returns null when value is null', () {
      expect(readDouble(null), isNull);
    });

    test('returns null when value is non-parseable string', () {
      expect(readDouble('not a number'), isNull);
    });
  });
}
