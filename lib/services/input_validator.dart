/// Input validation and sanitization utilities for secure user input handling
class InputValidator {
  /// Validate email format
  static String? validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return "Email is required";
    
    // Simple but effective email validation
    final pattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!pattern.hasMatch(email)) {
      return "Please enter a valid email address";
    }
    if (email.length > 254) {
      return "Email is too long";
    }
    return null;
  }

  /// Validate password strength (minimum 8 chars, mixed case, number)
  static String? validatePassword(String? value) {
    final password = (value ?? '').trim();
    if (password.isEmpty) return "Password is required";
    if (password.length < 8) return "Password must be at least 8 characters";
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password must contain at least one uppercase letter";
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Password must contain at least one lowercase letter";
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password must contain at least one number";
    }
    return null;
  }

  /// Validate name (alphanumeric and spaces only)
  static String? validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return "Name is required";
    if (name.length < 2) return "Please enter a valid name";
    if (name.length > 100) return "Name is too long";
    
    // Allow letters, spaces, hyphens, and apostrophes only
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name)) {
      return "Name can only contain letters, spaces, hyphens, and apostrophes";
    }
    return null;
  }

  /// Validate gestational age (1-42 weeks)
  static String? validateGestationalAge(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return "Gestational age is required";
    
    final number = int.tryParse(text);
    if (number == null) return "Please enter a valid number";
    if (number < 1 || number > 42) {
      return "Gestational age must be between 1 and 42 weeks";
    }
    return null;
  }

  /// Validate that two passwords match
  static String? validatePasswordMatch(String? value, String passwordToMatch) {
    if (value != passwordToMatch) return "Passwords do not match";
    return null;
  }

  /// Sanitize user input - remove dangerous characters
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[<>{}"|\\^`]'), '') // Remove dangerous chars
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Validate URL format
  static String? validateUrl(String? value) {
    final url = (value ?? '').trim();
    if (url.isEmpty) return "URL is required";
    
    try {
      Uri.parse(url);
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        return "URL must start with http:// or https://";
      }
      return null;
    } catch (e) {
      return "Please enter a valid URL";
    }
  }

  /// Check password strength level (weak/medium/strong)
  static String getPasswordStrengthLevel(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    if (strength <= 2) return "Weak";
    if (strength <= 4) return "Medium";
    return "Strong";
  }
}
