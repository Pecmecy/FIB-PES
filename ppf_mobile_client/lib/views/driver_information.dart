import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/views/search_screen.dart';

//Driver information view
class DriverInformation extends StatefulWidget {
  const DriverInformation(
      {super.key,
      required this.username,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.password,
      required this.password2,
      required this.selectedDate,
      required this.dni,
      required this.capacidad,
      required this.iban,
      required this.profileImage});

  //Information passed by register screen
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String password2;
  final DateTime? selectedDate;
  final String dni;
  final String capacidad;
  final String iban;
  final XFile? profileImage;

  @override
  State<DriverInformation> createState() => _DriverInformationState();
}

class _DriverInformationState extends State<DriverInformation> {
  //Variables to manage the charger types and preferences
  //chargerType: Mennekes, Tesla, Schuko, ChadeMO, CCS Combo2
  final List<bool> chargerType = [false, false, false, false, false];
  final Map<String, bool> preferences = {
    'canNotTravelWithPets': false,
    'listenToMusic': false,
    'noSmoking': false,
    'talkTooMuch': false
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        leading: Row(
          children: [
            //Back button
            IconButton(
              icon: Icon(Icons.close,
                  color: Theme.of(context).colorScheme.primary),
              //Click logic
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      resizeToAvoidBottomInset: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 40,
                  right: 40,
                ),
                child: Text.rich(TextSpan(
                  text: translation(context).selectChargerTypes,
                  style: Theme.of(context).textTheme.displayMedium,
                )),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ChargerTypes(
                  chargerType: chargerType,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 40,
                  right: 40,
                ),
                child: Text.rich(TextSpan(
                  text: translation(context).selectPreferences,
                  style: Theme.of(context).textTheme.displayMedium,
                )),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Preferences(
                  preferences: preferences,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                //Button to register as driver
                child: SignUpButton(
                  username: widget.username,
                  firstName: widget.firstName,
                  lastName: widget.lastName,
                  email: widget.email,
                  password: widget.password,
                  password2: widget.password2,
                  selectedDate: widget.selectedDate,
                  dni: widget.dni,
                  capacidad: widget.capacidad,
                  chargerType: chargerType,
                  preferences: preferences,
                  iban: widget.iban,
                  profileImage: widget.profileImage,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

//Button to register as driver
class SignUpButton extends StatefulWidget {
  const SignUpButton(
      {super.key,
      required this.username,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.password,
      required this.password2,
      required this.selectedDate,
      required this.dni,
      required this.capacidad,
      required this.chargerType,
      required this.preferences,
      required this.iban,
      required this.profileImage});

  //Variables needed to register as a driver
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String password2;
  final DateTime? selectedDate;
  final String dni;
  final String capacidad;
  final List<bool> chargerType;
  final Map<String, bool> preferences;
  final String iban;
  final XFile? profileImage;

  @override
  State<SignUpButton> createState() => _SignUpButtonState();
}

class _SignUpButtonState extends State<SignUpButton> {
  //Variables to manage errors
  var error = false;
  var errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //If an error has occurred while registering, a text is written indicating it
        if (error)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              errorMessage,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        SizedBox(
          height: 50,
          width: 250,
          child: ElevatedButton(
            onPressed: () async {
              //If no charger type has been selected, an error message is displayed
              if (widget.chargerType
                  .where((element) => element == true)
                  .toList()
                  .isEmpty) {
                setState(() {
                  error = true;
                  errorMessage = translation(context).selectAtLeastOneCharger;
                });
              } else {
                //If a charger type has been selected, put the selected charger identifyer in a list
                List<int> selectedChargerNames = [];
                if (widget.chargerType[0]) selectedChargerNames.add(1);
                if (widget.chargerType[1]) selectedChargerNames.add(2);
                if (widget.chargerType[2]) selectedChargerNames.add(3);
                if (widget.chargerType[3]) selectedChargerNames.add(4);
                if (widget.chargerType[4]) selectedChargerNames.add(5);
                //Register the driver
                String response = await userController.registerDriver(
                    widget.username,
                    widget.firstName,
                    widget.lastName,
                    widget.email,
                    widget.password,
                    widget.password2,
                    widget.selectedDate,
                    widget.dni,
                    widget.capacidad,
                    selectedChargerNames,
                    widget.preferences,
                    widget.iban);
                //If the connection has been executed correctly without errors
                if (response != translation(context).unexpectedError) {
                  if (widget.profileImage != null) {
                    userController.putUserAvatar(
                        widget.profileImage!, int.parse(response));
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SearchScreen()));
                } else {
                  //If there has been a problem logging in, we warn that there is an error.
                  setState(() {
                    error = true;
                    errorMessage = response;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              translation(context).registerAsDriver,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
      ],
    );
  }
}

//Widget to select charger types
class ChargerTypes extends StatefulWidget {
  const ChargerTypes({
    super.key,
    required this.chargerType,
  });

  final List<bool> chargerType;

  @override
  State<ChargerTypes> createState() => _ChargerTypesState();
}

class _ChargerTypesState extends State<ChargerTypes> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
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
        children: [
          _buildChargerTypeRow(context, 'Mennekes', 0),
          _buildChargerTypeRow(context, 'Tesla', 1),
          _buildChargerTypeRow(context, 'Schuko', 2),
          _buildChargerTypeRow(context, 'ChadeMO', 3),
          _buildChargerTypeRow(context, 'CCS Combo2', 4),
        ],
      ),
    );
  }

  Row _buildChargerTypeRow(BuildContext context, String label, int index) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        const Padding(padding: EdgeInsetsDirectional.symmetric(horizontal: 10)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text.rich(
              TextSpan(
                text: label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
        Switch(
          activeColor: Theme.of(context).colorScheme.onPrimaryContainer,
          activeTrackColor: Theme.of(context).colorScheme.secondary,
          inactiveThumbColor: Theme.of(context).colorScheme.onPrimaryContainer,
          inactiveTrackColor:
              Theme.of(context).colorScheme.onSecondaryContainer,
          value: widget.chargerType[index],
          onChanged: (value) {
            setState(() {
              widget.chargerType[index] = !widget.chargerType[index];
            });
          },
        ),
        const Padding(padding: EdgeInsetsDirectional.symmetric(horizontal: 10)),
      ],
    );
  }
}

//Widget to select preferences
class Preferences extends StatefulWidget {
  const Preferences({
    super.key,
    required this.preferences,
  });

  final Map<String, bool> preferences;

  @override
  State<Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
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
        children: [
          _buildPreferenceRow(
              context, translation(context).noPets, 'canNotTravelWithPets'),
          _buildPreferenceRow(
              context, translation(context).listenToMusic, 'listenToMusic'),
          _buildPreferenceRow(
              context, translation(context).noSmoking, 'noSmoking'),
          _buildPreferenceRow(
              context, translation(context).talkTooMuch, 'talkTooMuch'),
        ],
      ),
    );
  }

  Row _buildPreferenceRow(BuildContext context, String label, String key) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        const Padding(padding: EdgeInsetsDirectional.symmetric(horizontal: 10)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text.rich(
              TextSpan(
                text: label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
        Switch(
          activeColor: Theme.of(context).colorScheme.onPrimaryContainer,
          activeTrackColor: Theme.of(context).colorScheme.secondary,
          inactiveThumbColor: Theme.of(context).colorScheme.onPrimaryContainer,
          inactiveTrackColor:
              Theme.of(context).colorScheme.onSecondaryContainer,
          value: widget.preferences[key] ?? false,
          onChanged: (value) {
            setState(() {
              widget.preferences[key] = !(widget.preferences[key] ?? false);
            });
          },
        ),
        const Padding(padding: EdgeInsetsDirectional.symmetric(horizontal: 15)),
      ],
    );
  }
}
