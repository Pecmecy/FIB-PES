import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/views/search_screen.dart';
import 'package:ppf_mobile_client/views/welcome.dart';

import 'firebase_options.dart';

void main() async {
  /*
  const bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: true);
  const String userApi = String.fromEnvironment('USER_API', defaultValue: 'http://127.0.0.1:8081');
  const String routeApi = String.fromEnvironment('ROUTE_API', defaultValue: 'http://127.0.0.1:8080');

  print('Is Debug Mode: $isDebug');
  print('User API: $userApi');
  print('Route API: $routeApi');
  */
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      'pk_test_51P3PTWKT1SFkcH9NIxevafWwzBwQ9iud3la27rHSjAjMXg6ua2ygS4mtO9sM2oMnunXQLjUh9mFRwdfoKtRM4n4y00bnKIusn4';
  await Stripe.instance.applySettings();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final fcmToken = await FirebaseMessaging.instance.getToken();
  const storage = FlutterSecureStorage();
  await storage.write(key: 'firebaseToken', value: fcmToken);
  if (await storage.containsKey(key: 'token')) {
    userController.tokenFirebase();
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

Future<String?> getToken() async {
  final storage = FlutterSecureStorage();
  String? token = await storage.read(key: 'token');
  return token;
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) => {setLocale(locale)});
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localization',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFFFFF),
            primary: const Color(0xFF199600),
            secondary: const Color(0xFF54D618),
            tertiary: const Color(0xFFB3EFB2),
            background: const Color(0xFFFFFFFF),
            onPrimaryContainer: const Color(0xFFF7F7F7),
            onSecondaryContainer: const Color(0xFF969696),
            shadow: const Color(0x60464646)),
        textTheme: const TextTheme(
          //body: for most of the text
          bodySmall: TextStyle(
            color: Color(0xFF686868),
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF686868),
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF686868),
            fontSize: 22,
            fontWeight: FontWeight.normal,
          ),
          //display: body but bold
          displaySmall: TextStyle(
            color: Color(0xFF686868),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            color: Color(0xFF686868),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          displayLarge: TextStyle(
            color: Color(0xFF686868),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          //lable: for text hiperlinks
          labelSmall: TextStyle(
            color: Color(0xFF199600),
            fontSize: 14,
            //decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
          labelMedium: TextStyle(
            color: Color(0xFF199600),
            fontSize: 18,
            //decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
          labelLarge: TextStyle(
              fontSize: 22.0,
              color: Color(0xFF199600),
              //decoration: TextDecoration.underline,
              fontWeight: FontWeight.bold),
          //headline: for buttons
          headlineSmall: TextStyle(
              fontSize: 14,
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.normal),
          headlineMedium: TextStyle(
              fontSize: 18,
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.normal),
          headlineLarge: TextStyle(
              fontSize: 22,
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.normal),
          titleSmall: TextStyle(
            color: Color(0xFFF44336),
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          titleMedium: TextStyle(
            color: Color(0xFFF44336),
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
          titleLarge: TextStyle(
            color: Color(0xFFF44336),
            fontSize: 22,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      home: FutureBuilder<String?>(
        future: getToken(),
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Show loading spinner while waiting
          } else {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return snapshot.data == null
                  ? const Welcome()
                  : const SearchScreen(); // Check if token is null
            }
          }
        },
      ),
    );
  }
}
