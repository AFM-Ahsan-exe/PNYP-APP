import 'package:flutter_test/flutter_test.dart';

import 'package:pynp_app/core/validators/registration_validators.dart';

void main() {
  group('RegistrationValidators', () {
    group('required', () {
      test('returns error for null value', () {
        expect(
          RegistrationValidators.required(null, 'Name'),
          'Name is required',
        );
      });

      test('returns error for empty value', () {
        expect(RegistrationValidators.required('', 'Name'), 'Name is required');
      });

      test('returns error for whitespace-only value', () {
        expect(
          RegistrationValidators.required('   ', 'Name'),
          'Name is required',
        );
      });

      test('returns null for valid value', () {
        expect(RegistrationValidators.required('John Doe', 'Name'), isNull);
      });
    });

    group('cnic', () {
      test('returns error for null value', () {
        expect(RegistrationValidators.cnic(null), 'CNIC is required');
      });

      test('returns error for empty value', () {
        expect(RegistrationValidators.cnic(''), 'CNIC is required');
      });

      test('returns error for 12 digits', () {
        expect(
          RegistrationValidators.cnic('123451234567'),
          'Enter a valid 13-digit CNIC',
        );
      });

      test('returns error for 14 digits', () {
        expect(
          RegistrationValidators.cnic('12345123456789'),
          'Enter a valid 13-digit CNIC',
        );
      });

      test('returns error for non-numeric characters', () {
        expect(
          RegistrationValidators.cnic('12345ABCDEF1'),
          'Enter a valid 13-digit CNIC',
        );
      });

      test('returns null for valid 13 digits', () {
        expect(RegistrationValidators.cnic('1234512345671'), isNull);
      });

      test('accepts CNIC with dashes', () {
        expect(RegistrationValidators.cnic('12345-1234567-1'), isNull);
      });
    });

    group('phone', () {
      test('returns error for null value', () {
        expect(RegistrationValidators.phone(null), 'Phone number is required');
      });

      test('returns error for empty value', () {
        expect(RegistrationValidators.phone(''), 'Phone number is required');
      });

      test('returns error for invalid format', () {
        expect(
          RegistrationValidators.phone('1234567890'),
          'Use a valid Pakistan mobile number',
        );
      });

      test('returns null for valid 03xxxxxxxxx format', () {
        expect(RegistrationValidators.phone('03001234567'), isNull);
      });

      test('returns null for valid +923xxxxxxxxx format', () {
        expect(RegistrationValidators.phone('+923001234567'), isNull);
      });
    });

    group('email', () {
      test('returns error for null value', () {
        expect(RegistrationValidators.email(null), 'Email is required');
      });

      test('returns error for empty value', () {
        expect(RegistrationValidators.email(''), 'Email is required');
      });

      test('returns error for invalid format', () {
        expect(
          RegistrationValidators.email('not-an-email'),
          'Enter a valid email address',
        );
      });

      test('returns null for valid email', () {
        expect(RegistrationValidators.email('test@example.com'), isNull);
      });
    });

    group('password', () {
      test('returns error for null value', () {
        expect(RegistrationValidators.password(null), 'Password is required');
      });

      test('returns error for empty value', () {
        expect(RegistrationValidators.password(''), 'Password is required');
      });

      test('returns error for password shorter than 6 chars', () {
        expect(
          RegistrationValidators.password('12345'),
          'Password must be at least 6 characters',
        );
      });

      test('returns null for valid password', () {
        expect(RegistrationValidators.password('123456'), isNull);
      });
    });

    group('age', () {
      test('returns error for age below 15', () {
        final dob = DateTime(2020, 1, 1);
        expect(
          RegistrationValidators.age(dob),
          'Age must be between 15 and 35 years',
        );
      });

      test('returns error for age above 35', () {
        final dob = DateTime(1980, 1, 1);
        expect(
          RegistrationValidators.age(dob),
          'Age must be between 15 and 35 years',
        );
      });

      test('returns null for age 20', () {
        final dob = DateTime(2004, 1, 1);
        expect(RegistrationValidators.age(dob), isNull);
      });
    });
  });
}
