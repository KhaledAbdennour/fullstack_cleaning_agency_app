class AgeHelper {
  static int? calculateAge(String? birthdate) {
    if (birthdate == null || birthdate.isEmpty) {
      return null;
    }

    try {
      DateTime birthDate;

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
        birthDate = DateTime.parse(birthdate);
      }

      final today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return null;
    }
  }

  static String formatAge(String? birthdate) {
    final age = calculateAge(birthdate);
    if (age == null) {
      return 'N/A';
    }
    return '$age';
  }
}
