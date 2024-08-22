import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppf_mobile_client/Controllers/PaymentsController.dart';

main () async {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();
                await storage.write(
                    key: 'token',
                    value: 'c65b642f6712afcdc288b9d3e643aaf1301d47ab');
                    
  group('refundPayment', () {
    test('should refund payment of route 1 and user 3',
        () async {
      
      final result = await paymentsController.refund(3,1);

      expect(result, '');
    });
  });
}