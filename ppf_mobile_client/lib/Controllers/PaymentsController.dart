import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ppf_mobile_client/config.dart';

class PaymentsController {
  final http.Client client;
  PaymentsController({http.Client? client}) : client = client ?? http.Client();

  Future<String> processPayment(String paymentMethodId, int routeId) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      final url = Uri.parse('$paymentsApi/process_payment/');
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(
            {'payment_method_id': paymentMethodId, 'route_id': routeId}),
      );
      if (response.statusCode == 200) {
        return '';
      }
      Map<String, dynamic> responseBody = json.decode(response.body);
      String specificErrorMessage = responseBody['error'];
      return specificErrorMessage.substring(0, specificErrorMessage.length - 1);
    } catch (e) {
      String errorMessage = e.toString();
      return errorMessage;
    }
  }

  Future<String> refund(int user, int route) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      final url = Uri.parse('$paymentsApi/refund/');
      final response = await client.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
          body: jsonEncode({'user_id': user, 'route_id': route}));
          debugPrint(response.body);
      return '';
    } catch (e) {
      return e.toString();
    }
  }
}

final paymentsController = PaymentsController();
