import 'package:flutter/material.dart';
import 'package:ppf_mobile_client/views/login_screen.dart';
import 'package:ppf_mobile_client/views/register_screen.dart';
import 'package:ppf_mobile_client/classes/language.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/main.dart';
import 'package:ppf_mobile_client/views/search_screen.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<Language>(
              underline: const SizedBox(),
              icon: Icon(
                Icons.language,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onChanged: (Language? language) async {
                if (language != null) {
                  Locale _locale = await setLocale(language.languageCode);
                  MyApp.setLocale(context, _locale);
                }
              },
              items: Language.languageList()
                  .map<DropdownMenuItem<Language>>(
                    (e) => DropdownMenuItem<Language>(
                      value: e,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Text(
                            e.flag,
                            style: const TextStyle(fontSize: 30),
                          ),
                          Text(e.name)
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        leading: Row(
          children: [
            //Back button
            IconButton(
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.primary,
              ),
              //Click logic
              onPressed: () {
                Navigator.push(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildImage(context),
            _buildEslogan(context),
            _buildSignUp(context),
            _buildNoSignUp(context),
          ],
        ),
      ),
    );
  }

  Padding _buildSignUp(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 15,
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                ),
              );
            },
            child: Text(
              translation(context).signUp,
              style: Theme.of(context).textTheme.displayMedium,
            )),
      ),
    );
  }

  Padding _buildNoSignUp(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(
          bottom: 15,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LogIn(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 16, 89, 18),
              backgroundColor:
                  Colors.transparent, // Set the background color to transparent
            ),
            child: Text(
              translation(context).logIn,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ));
  }

  Padding _buildEslogan(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(
          top: 15,
          bottom: 15,
          left: 15,
          right: 15,
        ),
        child: Text.rich(
          TextSpan(
            text: translation(context).eslogan,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          textAlign: TextAlign.center,
        ));
  }

  Expanded _buildImage(BuildContext context) {
    return Expanded(
        child: SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Image.asset(
        'assets/welcomeImage.jpeg',
        fit: BoxFit.cover,
      ),
    ));
  }
}
