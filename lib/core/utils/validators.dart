class Validators {
  Validators._();

  static String? requiredField(String? value, {String field = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? value) {
    final emptyCheck = requiredField(value, field: 'Email');
    if (emptyCheck != null) {
      return emptyCheck;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final emptyCheck = requiredField(value, field: 'Password');
    if (emptyCheck != null) {
      return emptyCheck;
    }
    if (value!.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? name(String? value) {
    final emptyCheck = requiredField(value, field: 'Name');
    if (emptyCheck != null) {
      return emptyCheck;
    }
    if (value!.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
}
