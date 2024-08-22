import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';

main () async {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();
                await storage.write(
                    key: 'token',
                    value: 'c65b642f6712afcdc288b9d3e643aaf1301d47ab');
                    
  group('postUsers', () {
    test('should format date correctly and include image in FormData',
        () async {
      
      final result = await userController.usersSelf();

      expect(result, 3);
    });
  });
}