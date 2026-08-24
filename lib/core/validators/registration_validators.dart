class RegistrationValidators {
  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? cnic(String? value) {
    if (value == null || value.trim().isEmpty) return 'CNIC is required';
    if (!RegExp(r'^\d{13}$').hasMatch(value.replaceAll('-', ''))) {
      return 'Enter a valid 13-digit CNIC';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^(03\d{9}|\+923\d{9})$').hasMatch(value.trim())) {
      return 'Use a valid Pakistan mobile number';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static int computeAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  static String? age(DateTime dateOfBirth) {
    final age = computeAge(dateOfBirth);
    if (age < 15 || age > 35) return 'Age must be between 15 and 35 years';
    return null;
  }
}
