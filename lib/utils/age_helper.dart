/// Helper utility to calculate age from birthdate string
class AgeHelper {
  /// Calculate age from birthdate string (format: mm/dd/yyyy or yyyy-mm-dd)
  /// Returns age as integer, or null if birthdate is invalid
  static int? calculateAge(String? birthdate) {
    if (birthdate == null || birthdate.isEmpty) {
      return null;
    }

    try {
      DateTime birthDate;

      // Try mm/dd/yyyy format first (most common in this app)
      if (birthdate.contains('/')) {
        final parts = birthdate.split('/');
        if (parts.length == 3) {
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          birthDate = DateTime(year, month, day);
        } else {
          return null;
        }
      } else {
        // Try ISO8601 format (yyyy-mm-dd)
        birthDate = DateTime.parse(birthdate);
      }

      final today = DateTime.now();
      int age = today.year - birthDate.year;

      // Adjust if birthday hasn't occurred this year
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return null;
    }
  }

  /// Format age as string with "years" suffix
  static String formatAge(String? birthdate) {
    final age = calculateAge(birthdate);
    if (age == null) {
      return 'N/A';
    }
    return '$age';
  }
}
