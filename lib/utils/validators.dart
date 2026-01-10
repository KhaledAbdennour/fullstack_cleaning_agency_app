import 'algerian_addresses.dart';

class Validators {
  
  static String? validateUsername(String? value, {bool checkUnique = false}) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 3 || trimmed.length > 20) {
      return 'Username must be 3-20 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z]').hasMatch(trimmed)) {
      return 'Username must start with a letter';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    return null;
  }

  
  static String? validatePassword(String? value, {String? username, String? email}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8 || value.length > 64) {
      return 'Password must be 8-64 characters';
    }
    
    if (value.contains(' ')) {
      return 'Password cannot contain spaces';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    
    final specialChars = RegExp(r'[!@#\$%^&*()_+\-=\[\]{};:",<>\.?/\\|`~]');
    if (!specialChars.hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    
    if (username != null && value == username) {
      return 'Password cannot be the same as username';
    }
    
    if (email != null && value == email) {
      return 'Password cannot be the same as email';
    }
    
    return null;
  }

  
  static String? validateEmail(String? value, {bool checkUnique = false}) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final trimmed = value.trim().toLowerCase();
    
    if (trimmed.length > 254) {
      return 'Email must be 254 characters or less';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }

  
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full Name is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 2 || trimmed.length > 50) {
      return 'Full Name must be 2-50 characters';
    }
    
    
    final normalized = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(normalized)) {
      return 'Full Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  
  static String? validatePhone(String? value, {bool checkUnique = false}) {
    if (value == null || value.isEmpty) {
      return 'Phone Number is required';
    }
    
    final trimmed = value.trim();
    
    
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    
    // Must be between 9 and 10 digits
    if (digitsOnly.length < 9) {
      return 'Phone Number must be at least 9 digits';
    }
    
    if (digitsOnly.length > 10) {
      return 'Phone Number cannot be longer than 10 digits';
    }
    
    return null;
  }

  
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 5 || trimmed.length > 120) {
      return 'Address must be 5-120 characters';
    }
    
    
    final isValid = _isValidAlgerianAddress(trimmed);
    if (!isValid) {
      return 'Address must contain a valid Algerian wilaya (province)';
    }
    
    return null;
  }

  
  static bool _isValidAlgerianAddress(String address) {
    return AlgerianAddresses.isValidAddress(address);
  }

  
  static String? validateBirthdate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Birthdate is required';
    }
    
    try {
      
      final parts = value.split('/');
      if (parts.length != 3) {
        return 'Invalid date format. Use mm/dd/yyyy';
      }
      
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final birthDate = DateTime(year, month, day);
      final today = DateTime.now();
      
      if (birthDate.isAfter(today)) {
        return 'Birthdate cannot be in the future';
      }
      
      if (year < 1900) {
        return 'Birth year must be 1900 or later';
      }
      
      final age = today.year - birthDate.year;
      if (today.month < birthDate.month || 
          (today.month == birthDate.month && today.day < birthDate.day)) {
        
        if (age - 1 < 18) {
          return 'You must be at least 18 years old';
        }
      } else {
        if (age < 18) {
          return 'You must be at least 18 years old';
        }
      }
      
      return null;
    } catch (e) {
      return 'Invalid date format. Use mm/dd/yyyy';
    }
  }

  
  static String? validateBio(String? value, {bool required = true}) {
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }
    
    if (value == null || value.isEmpty) {
      return 'Bio is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 20 || trimmed.length > 500) {
      return 'Bio must be 20-500 characters';
    }
    
    
    if (RegExp(r'<[^>]*>').hasMatch(trimmed)) {
      return 'Bio cannot contain HTML or script tags';
    }
    
    return null;
  }

  
  static String? validateServices(String? value) {
    if (value == null || value.isEmpty) {
      return 'Services Offered is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 3 || trimmed.length > 200) {
      return 'Services Offered must be 3-200 characters';
    }
    
    return null;
  }

  
  static String? validateHourlyRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Hourly Rate is required';
    }
    
    final trimmed = value.trim();
    
    final rate = double.tryParse(trimmed);
    if (rate == null) {
      return 'Hourly Rate must be a valid number';
    }
    
    if (rate <= 0) {
      return 'Hourly Rate must be greater than 0';
    }
    
    if (rate < 200 || rate > 20000) {
      return 'Hourly Rate must be between 200 and 20000 DZD';
    }
    
    return null;
  }

  
  static String? validateAgencyName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Agency Name is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 2 || trimmed.length > 100) {
      return 'Agency Name must be 2-100 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9\s\-\&]+$').hasMatch(trimmed)) {
      return 'Agency Name can only contain letters, numbers, spaces, hyphens, and &';
    }
    
    
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Agency Name cannot be only numbers';
    }
    
    return null;
  }

  
  static String? validateBusinessId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Business Registration ID is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 5 || trimmed.length > 30) {
      return 'Business Registration ID must be 5-30 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9\-]+$').hasMatch(trimmed)) {
      return 'Business Registration ID can only contain letters, numbers, and hyphens';
    }
    
    return null;
  }
}

