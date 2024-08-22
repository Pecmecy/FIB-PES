import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
                await storage.write(
                    key: 'token',
                    value: 'c65b642f6712afcdc288b9d3e643aaf1301d47ab');
  group('putUsers', () {
    test('should format date correctly and include image in FormData',
        () async {
      final imagePath = 'assets/logo.png';
      int id = await userController.usersSelf();

      final result = await userController.putUserAvatar(
        XFile.fromData(File(imagePath).readAsBytesSync()),
        id,
      );

      expect(result, '');
    });
  });
}
