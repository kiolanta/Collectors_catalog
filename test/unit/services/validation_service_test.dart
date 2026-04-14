import 'package:collectors_catalog/services/validation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidationService.validateEmail', () {
    test('returns error when email is null', () {
      expect(ValidationService.validateEmail(null), 'Please enter your email');
    });

    test('returns error when email is empty', () {
      expect(ValidationService.validateEmail(''), 'Please enter your email');
    });

    test('returns error for invalid email format', () {
      expect(
        ValidationService.validateEmail('invalid-email'),
        'Please enter a valid email address',
      );
    });

    test('returns null for valid email', () {
      expect(ValidationService.validateEmail('user@example.com'), isNull);
    });
  });

  group('ValidationService.validatePassword', () {
    test('returns error when password is null', () {
      expect(
        ValidationService.validatePassword(null),
        'Please enter your password',
      );
    });

    test('returns error when password is too short', () {
      expect(
        ValidationService.validatePassword('Ab1!'),
        'Password must be at least 6 characters',
      );
    });

    test('returns error when uppercase is missing', () {
      expect(
        ValidationService.validatePassword('abcd12!'),
        'Password must contain at least one uppercase letter',
      );
    });

    test('returns error when lowercase is missing', () {
      expect(
        ValidationService.validatePassword('ABCD12!'),
        'Password must contain at least one lowercase letter',
      );
    });

    test('returns error when number is missing', () {
      expect(
        ValidationService.validatePassword('Abcdef!'),
        'Password must contain at least one number',
      );
    });

    test('returns error when special character is missing', () {
      expect(
        ValidationService.validatePassword('Abcdef1'),
        'Password must contain at least one special character',
      );
    });

    test('returns null for strong password', () {
      expect(ValidationService.validatePassword('Strong1!'), isNull);
    });
  });

  group('ValidationService.validateConfirmPassword', () {
    test('returns error when confirm password is empty', () {
      expect(
        ValidationService.validateConfirmPassword('', 'Strong1!'),
        'Please confirm your password',
      );
    });

    test('returns error when passwords do not match', () {
      expect(
        ValidationService.validateConfirmPassword('Wrong1!', 'Strong1!'),
        'Passwords do not match',
      );
    });

    test('returns null when passwords match', () {
      expect(
        ValidationService.validateConfirmPassword('Strong1!', 'Strong1!'),
        isNull,
      );
    });
  });

  group('ValidationService.validateName', () {
    test('returns error when name is empty', () {
      expect(
        ValidationService.validateName('', 'Name'),
        'Please enter your Name',
      );
    });

    test('returns error when name is too short', () {
      expect(
        ValidationService.validateName('A', 'Name'),
        'Name must be at least 2 characters',
      );
    });

    test('returns error when name contains non-letters', () {
      expect(
        ValidationService.validateName('John3', 'Name'),
        'Name can only contain letters',
      );
    });

    test('returns null for valid name', () {
      expect(ValidationService.validateName('John Doe', 'Name'), isNull);
    });
  });
}
