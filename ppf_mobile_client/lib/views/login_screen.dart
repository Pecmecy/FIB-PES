import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/views/forgot_password.dart';
import 'package:ppf_mobile_client/views/register_screen.dart';
import 'package:ppf_mobile_client/views/search_screen.dart';

// Principal Widget of the view
class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: _botonBack(),
        backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset(
                  "assets/logo.png",
                  height: 200,
                  width: 200,
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
                child: Password(
                  controller: _passwordController,
                ),
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: ForgotPasswordLink(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: LogInButton(
                    emailController: _emailController,
                    passwordController: _passwordController),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: AutentificationButton(
                  icon: Image.asset(
                    'assets/GoogleLogo.png',
                    width: 50.0,
                    height: 50.0,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(10.0),
                child: SignUpOption(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonBack() {
    return Row(
      children: [
        // Back button
        IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.primary,
          ),
          // Click logic
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

// Widget to register in the application
class SignUpOption extends StatelessWidget {
  const SignUpOption({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            translation(context).noAccount,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(
            width: 5,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            child: Text(
              translation(context).signUp,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ]),
        if (!const bool.fromEnvironment('dart.vm.product'))
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(
              translation(context).useDebugUser,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(
              width: 5,
            ),
            GestureDetector(
              onTap: () async {
                const storage = FlutterSecureStorage();
                await storage.write(
                    key: 'token',
                    value: 'c65b642f6712afcdc288b9d3e643aaf1301d47ab');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: Text(
                'debugUser',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ]),
      ],
    );
  }
}

// Widget to start log in with other platforms
class AutentificationButton extends StatelessWidget {
  const AutentificationButton({super.key, required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        bool success = await userController.loginWithGoogle();
        if (success) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          );
        }
      },
      icon: icon,
      color: Colors.white,
    );
  }
}

// Button to confirm credentials and login to the application
class LogInButton extends StatefulWidget {
  const LogInButton(
      {super.key,
      required this.emailController,
      required this.passwordController});

  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  State<LogInButton> createState() => _LogInButtonState();
}

class _LogInButtonState extends State<LogInButton> {
  // Variable that determines whether an error message is to be printed or not.
  var error = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // If an error has occurred while starting the session, a text is written indicating it
        if (error)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              translation(context).invalidCredentials,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        SizedBox(
          height: 50,
          width: 250,
          child: ElevatedButton(
            onPressed: () async {
              String token = await userController.logInUser(
                  widget.emailController.text, widget.passwordController.text);
              // If the connection has been executed correctly without errors
              if (token != "Invalid credentials") {
                const storage = FlutterSecureStorage();
                await storage.write(key: 'token', value: token);
                Navigator.push(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              } else {
                // If there has been a problem logging in, we warn that there is an error.
                setState(() {
                  error = true;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              translation(context).logIn,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
      ],
    );
  }
}

// Widget to go to ForgotPassword view
class ForgotPasswordLink extends StatelessWidget {
  const ForgotPasswordLink({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ForgotPassword()),
        );
      },
      child: Text(
        translation(context).forgotPassword,
        style: Theme.of(context).textTheme.labelSmall,
      ),
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
      child: TextField(
        style: Theme.of(context).textTheme.bodyMedium,
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).colorScheme.background,
          hintText: translation(context).email,
          hintStyle: Theme.of(context).textTheme.bodyMedium,
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
        ),
      ),
    );
  }
}

// Widget to display the user's password
class Password extends StatefulWidget {
  const Password({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<Password> createState() => _PasswordState();
}

class _PasswordState extends State<Password> {
  // Variable that determines whether to hide the written text or not.
  var hide = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Theme.of(context).colorScheme.background,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 10.0,
          ),
        ],
      ),
      child: TextField(
        // Assign the TextField controller
        obscureText: hide,
        style: Theme.of(context).textTheme.bodyMedium,
        controller: widget.controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).colorScheme.background,
          hintText: translation(context).password,
          hintStyle: Theme.of(context).textTheme.bodyMedium,
          contentPadding:
              const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.background,
              width: 4,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          suffixIcon: IconButton(
            // Depending on the value of hide, an icon is assigned to it.
            icon: Icon(hide ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                hide = !hide;
              });
            },
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.background,
              width: 0,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
