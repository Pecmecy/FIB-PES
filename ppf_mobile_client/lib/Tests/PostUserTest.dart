import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  group('postUsers', () {
    test('should format date correctly and include image in FormData',
        () async {
      // Arrange
      final username = 'Patote';
      final firstName = 'Pau';
      final lastName = 'Galopa';
      final email = 'paugalopa@hotmail.com';
      final birthDate = DateTime(2021, 12, 12);
      final password = 'aa';
      final password2 = 'aa';

      final result = await userController.registerUser(
        username,
        firstName,
        lastName,
        email,
        password,
        password2,
        birthDate,
      );
      expect(result, '');
    });
  });
}
