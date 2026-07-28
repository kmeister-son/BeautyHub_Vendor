/// Field validators for the vendor login form.
String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validatePassword(String? value) =>
    (value == null || value.isEmpty) ? 'Enter your password' : null;

String? validateNewPassword(String? value) {
  if (value == null || value.isEmpty) return 'Choose a password';
  if (value.length < 8) return 'Use at least 8 characters';
  return null;
}

String? validateResetCode(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter the code from your email';
  if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'The code is 6 digits';
  return null;
}
