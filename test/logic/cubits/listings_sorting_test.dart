import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}

DateTime _profileRecency(Map<String, dynamic> profile) {
  final updated = _parseDate(profile['updated_at']);
  final created = _parseDate(profile['created_at']);
  return updated ?? created ?? DateTime.fromMillisecondsSinceEpoch(0);
}

int _compareProfilesByRatingAndRecency(
  Map<String, dynamic> a,
  Map<String, dynamic> b,
) {
  final ratingA = (a['rating'] as double? ?? 0.0);
  final ratingB = (b['rating'] as double? ?? 0.0);
  final ratingCmp = ratingB.compareTo(ratingA);
  if (ratingCmp != 0) return ratingCmp;
  final recencyA = _profileRecency(a);
  final recencyB = _profileRecency(b);
  return recencyB.compareTo(recencyA);
}

void main() {
  group('Profile sorting by rating and recency', () {
    test('sorts by rating descending', () {
      final profiles = [
        {'id': 1, 'rating': 3.5, 'name': 'Low Rating'},
        {'id': 2, 'rating': 5.0, 'name': 'High Rating'},
        {'id': 3, 'rating': 4.0, 'name': 'Mid Rating'},
      ];

      profiles.sort(_compareProfilesByRatingAndRecency);

      expect(profiles[0]['id'], equals(2));
      expect(profiles[1]['id'], equals(3));
      expect(profiles[2]['id'], equals(1));
    });

    test('sorts by recency when ratings are equal', () {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(days: 5));
      final later = now.subtract(const Duration(days: 2));

      final profiles = [
        {
          'id': 1,
          'rating': 4.5,
          'name': 'Earlier',
          'updated_at': earlier,
        },
        {
          'id': 2,
          'rating': 4.5,
          'name': 'Later',
          'updated_at': later,
        },
      ];

      profiles.sort(_compareProfilesByRatingAndRecency);

      expect(profiles[0]['id'], equals(2));
      expect(profiles[1]['id'], equals(1));
    });

    test('prefers updated_at over created_at for recency', () {
      final created = DateTime(2024, 1, 1);
      final updated = DateTime(2024, 1, 15);

      final profiles = [
        {
          'id': 1,
          'rating': 4.0,
          'created_at': created,
          'updated_at': updated,
        },
        {
          'id': 2,
          'rating': 4.0,
          'created_at': updated,
        },
      ];

      profiles.sort(_compareProfilesByRatingAndRecency);

      expect(profiles[0]['id'], equals(1));
    });

    test('handles missing dates gracefully', () {
      final profiles = [
        {
          'id': 1,
          'rating': 4.0,
        },
        {
          'id': 2,
          'rating': 4.0,
          'created_at': DateTime(2024, 1, 1),
        },
      ];

      profiles.sort(_compareProfilesByRatingAndRecency);

      expect(profiles[0]['id'], equals(2));
    });

    test('handles Timestamp format for dates', () {
      final timestamp1 = Timestamp.fromDate(DateTime(2024, 1, 10));
      final timestamp2 = Timestamp.fromDate(DateTime(2024, 1, 15));

      final profiles = [
        {
          'id': 1,
          'rating': 4.0,
          'updated_at': timestamp1,
        },
        {
          'id': 2,
          'rating': 4.0,
          'updated_at': timestamp2,
        },
      ];

      profiles.sort(_compareProfilesByRatingAndRecency);

      expect(profiles[0]['id'], equals(2));
    });

    test('handles int milliseconds for dates', () {
      final ms1 = DateTime(2024, 1, 10).millisecondsSinceEpoch;
      final ms2 = DateTime(2024, 1, 15).millisecondsSinceEpoch;

      final profiles = [
        {
          'id': 1,
          'rating': 4.0,
          'created_at': ms1,
        },
        {
          'id': 2,
          'rating': 4.0,
          'created_at': ms2,
        },
      ];

      profiles.sort(_compareProfilesByRatingAndRecency);

      expect(profiles[0]['id'], equals(2));
    });
  });
}
