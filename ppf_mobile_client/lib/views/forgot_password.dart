import 'package:flutter/material.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/views/login_screen.dart';

// Principal Widget of the view
class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Transform.rotate(
              angle: 0,
              child: Container(
                width: screenWidth,
                height: screenHeight,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF), // White color at the top
                      Color(0xFFCADEBC), // Green color at the bottom
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -10,
            left: -10,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 120,
                height: 120,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: 40,
            child: Transform.rotate(
              angle: -0.65,
              child: Container(
                width: 150,
                height: 150,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: screenHeight - 110,
            left: screenWidth - 120,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: 240,
                height: 240,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: screenHeight - 120,
            left: -105,
            child: Transform.rotate(
              angle: 0.20,
              child: Container(
                width: 120,
                height: 120,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: screenHeight - 170,
            left: -40,
            child: Transform.rotate(
              angle: 0.80,
              child: Container(
                width: 80,
                height: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: screenWidth - 40,
            child: Transform.rotate(
              angle: -0.80,
              child: Container(
                width: 80,
                height: 80,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              ),
            ),
          ),
          Center(
            child: Container(
              width: screenWidth * 0.85,
              height: 285,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow,
                    blurRadius: 10.0,
                  ),
                ],
                borderRadius: BorderRadius.circular(20.0),
                color: Theme.of(context).colorScheme.background,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      translation(context).recoverPassword,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Email(
                      controller: _emailController,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: _buildChangePassword(context),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.038,
            left: 0,
            child: IconButton(
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.background,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          )
        ],
      ),
    );
  }

  SizedBox _buildChangePassword(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 250,
      child: ElevatedButton(
        onPressed: () async {
          // Send email
          String response =
              await userController.changePasswaord(_emailController.text);
          if (response != "") {
            _showError(response);
          } else {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(
                      translation(context).emailSent,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    content: Text(
                      translation(context).emailSentInstructions,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    actions: [
                      TextButton(
                        child: Text('Ok',
                            style: Theme.of(context).textTheme.labelMedium),
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LogIn()));
                        },
                      ),
                    ],
                  );
                });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        child: Text(
          translation(context).sendEmail,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }

  Future<void> _showError(String error) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            translation(context).error,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// Widget to indicate the user's email address
class Email extends StatelessWidget {
  const Email({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow,
                blurRadius: 10.0,
              ),
            ],
            borderRadius: BorderRadius.circular(20.0),
            color: Theme.of(context).colorScheme.background),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Theme.of(context).colorScheme.background,
          ),
          child: TextField(
            // Assign the TextField controller
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.background,
              contentPadding:
                  const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.background,
                  width: 0,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.background,
                  width: 0,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              hintStyle: Theme.of(context).textTheme.bodyMedium,
              hintText: translation(context).email,
            ),
          ),
        ));
  }
}
