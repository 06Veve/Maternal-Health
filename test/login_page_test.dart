import 'package:bebezen/services/input_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Login validation', () {
    test('accepts a valid email', () {
      expect(InputValidator.validateEmail('test@example.com'), isNull);
    });

    test('rejects an invalid email', () {
      expect(InputValidator.validateEmail('invalid-email'), isNotNull);
    });

    test('requires a password', () {
      expect(InputValidator.validatePassword(''), isNotNull);
    });

    test('accepts a strong password', () {
      expect(InputValidator.validatePassword('Password123'), isNull);
    });

    test('requires matching password confirmation', () {
      expect(
        InputValidator.validatePasswordMatch('Password124', 'Password123'),
        isNotNull,
      );
      expect(
        InputValidator.validatePasswordMatch('Password123', 'Password123'),
        isNull,
      );
    });
  });
}
