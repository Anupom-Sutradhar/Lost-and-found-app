import '../config/constants.dart';

class Validators {
  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? universityEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final email = value.trim().toLowerCase();
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\-\.]+$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email';
    if (!email.endsWith('@${AppConstants.universityEmailDomain}')) {
      return 'Use your @${AppConstants.universityEmailDomain} email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? studentId(String? value) {
    if (value == null || value.trim().isEmpty) return 'Student ID is required';
    if (value.trim().length < 5) return 'Student ID looks too short';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 10) return 'Enter a valid phone number';
    return null;
  }
}
