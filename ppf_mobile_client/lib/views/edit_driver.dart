import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/Models/Driver.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/global_widgets/dialog_utils.dart';
import 'package:ppf_mobile_client/views/login_screen.dart';
import 'package:ppf_mobile_client/views/my_profile.dart';

class EditDriver extends StatefulWidget {
  const EditDriver({
    super.key,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.password2,
    required this.selectedDate,
    required this.profileImage,
    required this.capacidad,
    required this.iban,
    required this.newDriver,
  });

  // Information passed by register screen
  final String username;
  final String firstName;
  final String lastName;
  final String password;
  final String password2;
  final DateTime? selectedDate;
  final XFile? profileImage;
  final String capacidad;
  final String iban;
  final bool newDriver;

  @override
  State<EditDriver> createState() => _EditDriverState();
}

class _EditDriverState extends State<EditDriver> {
  List<bool> chargerType = [false, false, false, false, false];
  Map<String, bool> preferences = {
    'canNotTravelWithPets': false,
    'listenToMusic': false,
    'noSmoking': false,
    'talkTooMuch': false
  };
  final TextEditingController _dniController = TextEditingController();

  Driver? driver;
  bool _isDataLoaded = false;
  Future<Driver?>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _getDriverInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      resizeToAvoidBottomInset: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<Driver?>(
            future: _dataFuture,
            builder: (BuildContext context, AsyncSnapshot<Driver?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.data != null && !_isDataLoaded) {
                  driver = snapshot.data;
                  chargerType = driver!.chargerTypes;
                  preferences = driver!.preferences;
                  _isDataLoaded = true;
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    widget.newDriver
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(5),
                                child: Text.rich(TextSpan(
                                  text: translation(context).enterDNI,
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                              ),
                              // DNI text field
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: _buildTextField(
                                    _dniController, translation(context).dni),
                              ),
                            ],
                          )
                        : const SizedBox(height: 10.0),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 40,
                        right: 40,
                      ),
                      child: Text.rich(TextSpan(
                        text: translation(context).selectChargerTypes,
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _chargerTypes(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 40,
                        right: 40,
                      ),
                      child: Text.rich(TextSpan(
                        text: translation(context).selectPreferences,
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _preferences(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      // Button to register as driver
                      child: _signUpButton(),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _signUpButton() {
    return Column(
      children: [
        SizedBox(
          height: 50,
          width: 250,
          child: ElevatedButton(
            onPressed: () async {
              showConfirmationDialog(
                  context: context,
                  title: "",
                  content:
                      translation(context).confirmChangeToDriver,
                  onConfirm: () async {
                    if (chargerType
                        .where((element) => element == true)
                        .toList()
                        .isEmpty) {
                      _showError(translation(context).selectAtLeastOneCharger);
                    } else {
                      // If a charger type has been selected, put the selected charger identifier in a list
                      List<int> selectedChargerNames = [];
                      if (chargerType[0]) selectedChargerNames.add(1);
                      if (chargerType[1]) selectedChargerNames.add(2);
                      if (chargerType[2]) selectedChargerNames.add(3);
                      if (chargerType[3]) selectedChargerNames.add(4);
                      if (chargerType[4]) selectedChargerNames.add(5);

                      int id = await userController.usersSelf();
                      String response = await _putuser(id);
                      if (response == '') {
                        // Driver still wants to be driver
                        if (!widget.newDriver) {
                          // Edit the driver information
                          response = await userController.putDriver(
                            widget.username,
                            widget.firstName,
                            widget.lastName,
                            widget.password,
                            widget.password2,
                            widget.selectedDate!,
                            widget.capacidad,
                            selectedChargerNames,
                            preferences,
                            widget.iban,
                            id,
                          );
                          // If the connection has been executed correctly without errors
                          if (response == '') {
                            Navigator.push(
                                // ignore: use_build_context_synchronously
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MyProfile(
                                          id: id,
                                        )));
                          } else {
                            // If there is an error, show the error message
                            _showError(response);
                          }
                        } else {
                          // Change user to driver
                          String response = await userController.userToDriver(
                            _dniController.text,
                            widget.capacidad,
                            selectedChargerNames,
                            preferences,
                            widget.iban,
                          );
                          if (response == '') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LogIn(),
                              ),
                            );
                          } else {
                            _showError(response);
                          }
                        }
                      } else {
                        _showError(response);
                      }
                    }
                  });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(
              translation(context).saveChanges,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chargerTypes() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.white,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
        ),
        Text.rich(TextSpan(
          text: label,
          style: const TextStyle(fontSize: 18.0, color: Colors.black),
        )),
        const Spacer(),
        Switch(
          activeColor: Colors.white,
          activeTrackColor: Colors.lightGreenAccent[700],
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[500],
          value: chargerType[index],
          onChanged: (value) {
            setState(() {
              chargerType[index] = !chargerType[index];
            });
          },
        ),
        const Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
        ),
      ],
    );
  }

  Widget _preferences() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.white,
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
          value: preferences[key] ?? false,
          onChanged: (value) {
            setState(() {
              preferences[key] = !(preferences[key] ?? false);
            });
          },
        ),
        const Padding(padding: EdgeInsetsDirectional.symmetric(horizontal: 15)),
      ],
    );
  }
  // Regular text field
  Widget _buildTextField(TextEditingController contr, String? hint) {
    return Container(
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
      child: TextField(
        controller: contr,
        autofocus: false,
        style: const TextStyle(fontSize: 18.0),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
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

  Future<Driver?> _getDriverInfo() async {
    int id = await userController.usersSelf();
    return await userController.getDriverInformation(id);
  }

  // Show errors
  Future<void> _showError(String error) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translation(context).error),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(translation(context).ok),
            ),
          ],
        );
      },
    );
  }

  Future<String> _putuser(int id) async {
    // Register non-driver if all fields are full
    return await userController.putUser(
      widget.username,
      widget.firstName,
      widget.lastName,
      widget.password,
      widget.password2,
      widget.selectedDate!,
      widget.profileImage,
      id,
    );
  }
}
