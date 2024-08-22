import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:ppf_mobile_client/Controllers/RouteController.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/views/search_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final int route_id;
  const CheckoutScreen({super.key, required this.route_id});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  CardFieldInputDetails? _card;
  bool loading = false;
  get http => null;

  @override
  Scaffold build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              CardFormField(
                onCardChanged: (card) {
                  setState(() {
                    _card = card;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Center(
          child: FilledButton(
              onPressed: loading ? null : () => handlePayment(),
              child: Text(translation(context).pay)),
        ),
      ),
    );
  }

  handlePayment() async {
    if (_card?.complete != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translation(context).pleaseEnterCardDetails),
        ),
      );
      return;
    }
    setState(() {
      loading = true;
    });

    try {
      await processPayment();
    } catch (e) {
      throw Exception('Error processing payment: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  processPayment() async {
    final paymentMethod = await Stripe.instance.createPaymentMethod(
      params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData()),
    );
    print(paymentMethod.id);
    final response =
        await routeController.joinRoute(paymentMethod.id, widget.route_id);
    if (response == '') {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const SearchScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translation(context).paymentError),
        ),
      );
    }
  }
}
