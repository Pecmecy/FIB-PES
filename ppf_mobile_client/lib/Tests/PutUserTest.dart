import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  await storage.write(
      key: 'token', value: 'c65b642f6712afcdc288b9d3e643aaf1301d47ab');
  group('putUsers', () {
    test('should format date correctly and include image in FormData',
        () async {
      // Arrange
      final username = 'NombreUno';
      final firstName = 'Ke';
      final lastName = 'Kohone';
      final birthDate = DateTime(2021, 12, 12);
      final password = 'aa';
      final password2 = 'aa';
      int id = await userController.usersSelf();

      final result = await userController.putUser(
        username,
        firstName,
        lastName,
        password,
        password2,
        birthDate,
        null,
        id,
      );

      expect(result, '');
    });
  });
}
