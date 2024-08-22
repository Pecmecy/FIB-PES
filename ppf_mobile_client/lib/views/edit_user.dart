import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/Models/Driver.dart';
import 'package:ppf_mobile_client/Models/Users.dart';
import 'package:ppf_mobile_client/classes/language.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/global_widgets/NavigationBar.dart';
import 'package:ppf_mobile_client/global_widgets/dialog_utils.dart';
import 'package:ppf_mobile_client/main.dart';
import 'package:ppf_mobile_client/views/edit_driver.dart';
import 'package:ppf_mobile_client/views/login_screen.dart';
import 'package:ppf_mobile_client/views/my_profile.dart';

class EditUser extends StatefulWidget {
  const EditUser({super.key});

  @override
  State<EditUser> createState() => _EditUserState();
}

class _EditUserState extends State<EditUser> {
  // Register variables
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _capacidadMaximaDelVehiculoController =
      TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  var hide1 = true;
  DateTime? _selectedDate;
  XFile? _profileImage;
  bool _isDriver = false;
  User? logedUser;
  Driver? driver;
  bool _isDataLoaded = false;
  // Define a Future variable at the top of your widget
  Future<List<dynamic>>? _dataFuture;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    // Call your function in initState and store the Future in _dataFuture
    _dataFuture = Future.wait([_getUserInfo(), _getDriverInfo()]);
    initDriverData();
  }

  initDriverData() async {
    driver = await _getDriverInfo();
  }

  // Register screen components
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
      ),
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      resizeToAvoidBottomInset: true,
      // SingleChildScrollView to deal with overflow when opening keyboard
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        // Column to show components from top to bottom
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<List<dynamic>>(
              future: _dataFuture,
              builder: (BuildContext context,
                  AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // show loading spinner while waiting for data
                } else if (snapshot.hasError) {
                  return Text(
                    translation(context).error + ': ${snapshot.error}',
                  ); // show error message if any error occurred
                } else {
                  logedUser = snapshot.data![0];
                  _userNameController.text = logedUser!.username;
                  _firstNameController.text = logedUser!.firstName;
                  _lastNameController.text = logedUser!.lastName;
                  _selectedDate = logedUser?.birthDate;

                  if (snapshot.data![1] != null && !_isDataLoaded) {
                    driver = snapshot.data![1];
                    _isDriver = true;
                    _capacidadMaximaDelVehiculoController.text =
                        driver!.autonomy.toString();
                    _ibanController.text = driver!.IBAN;
                  }

                  return Column(
                    // Back button to go back to login screen
                    children: [
                      const SizedBox(height: 25.0),

                      // Profile picture
                      _imageSelector(),
                      const SizedBox(height: 10.0),

                      // Username text field
                      _buildTextField(
                          _userNameController, translation(context).username),
                      const SizedBox(height: 10.0),

                      // Name text field
                      _buildNameSelector(),
                      const SizedBox(height: 10.0),

                      // Date selection field
                      _buildDateSelector(),
                      const SizedBox(height: 10.0),

                      // Password text field
                      _buildPasswordChanger(),
                      const SizedBox(height: 10.0),

                      // Confirm password text field
                      _buildChangePasswordFieldsSelector(),
                      const SizedBox(height: 2.0),

                      // Choosing to be or not to be (a driver :D)
                      _buildDriverSelector(),
                      const SizedBox(height: 10.0),

                      // Driver specific fields, only shown if _isDriver is true
                      _buildDriverFieldsSelector(),
                      const SizedBox(height: 20.0),

                      // Register button
                      _buildEditButton(),
                      const SizedBox(height: 30.0),
                    ],
                  );
                }
              },
            ),

            // Erase button
            _buildEraseButton(),
          ],
        ),
      ),
      bottomNavigationBar: const Bar(selectedIndex: 4),
    );
  }

  // Constructors

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

  // Password text field
  Widget _buildPasswordSelector(TextEditingController pasCont, String hint) {
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
        controller: pasCont,
        autofocus: false,
        obscureText: hide1,
        style: Theme.of(context).textTheme.bodyMedium,
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
          // Hide/Show password button
          suffixIcon: IconButton(
            icon: Icon(hide1 ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                hide1 = !hide1;
              });
            },
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          ),
        ),
      ),
    );
  }

  // Number selection text field
  Widget _buildNumberField(TextEditingController contr, String? hint) {
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
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9 .]'))
        ],
        controller: contr,
        autofocus: false,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
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
          contentPadding:
              const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
        ),
      ),
    );
  }

  // Date selection field
  Widget _buildDateSelector() {
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
      child: InkWell(
        onTap: () => _selectDate(context),
        child: InputDecorator(
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
          ),
          child: _selectedDate == null
              ? Text.rich(TextSpan(
                  text: translation(context).birthDate,
                  style: Theme.of(context).textTheme.bodyMedium,
                ))
              : Text.rich(TextSpan(
                  text:
                      '${_selectedDate?.day}/${_selectedDate?.month}/${_selectedDate?.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                )),
        ),
      ),
    );
  }

  // Register button
  Widget _buildEditButton() {
    return Container(
      height: 65,
      width: 350,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        ),

        // Actions when the button is pressed
        onPressed: () async {
          // Register variables
          String userName = _userNameController.text;
          String firstName = _firstNameController.text;
          String lastName = _lastNameController.text;
          String password = _passwordController.text;
          String password2 = _confirmPasswordController.text;
          String capacidad = _capacidadMaximaDelVehiculoController.text;
          String iban = _ibanController.text;
          String response;

          // Show error message when passwords are different
          if (_changePassword && password != password2) {
            _showError(translation(context).passwordsDoNotMatch);
          }

          // Password and email are valid
          else {
            // Driver case
            if (_isDriver) {
              // Show error message if one of the fields is empty
              if (capacidad.isEmpty || iban.isEmpty) {
                _showError(translation(context).fillAllFields);
              } else if (!isValidIBAN(iban)) {
                _showError(translation(context).enterValidIBAN);
              }

              // Still wants to be driver
              else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditDriver(
                      username: userName,
                      firstName: firstName,
                      lastName: lastName,
                      password: password,
                      password2: password2,
                      selectedDate: _selectedDate,
                      profileImage: _profileImage,
                      capacidad: capacidad,
                      iban: iban,
                      newDriver: driver == null,
                    ),
                  ),
                );
              }
            }

            // Wants to stop being driver
            else if (driver != null) {
              int id = await userController.usersSelf();
              showConfirmationDialog(context: context, title:  "", content: translation(context).confirmChangeToUser, onConfirm: () async {
              response = await userController.putUser(
                userName,
                firstName,
                lastName,
                _changePassword ? password : '',
                _changePassword ? password2 : '',
                _selectedDate!,
                _profileImage,
                id,
              );
              if (response == '') {
                response = await userController.driverToUser();
                if (response == '') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LogIn(),
                    ),
                  );
                }

                // Show error while registering
                else {
                  _showError(response);
                }
              } else {
                _showError(response);
              }
            });
            }

            // Non driver case
            else {
              // Redirect to home screen if registered correctly
              int id = await userController.usersSelf();
              // Register non driver if all fields are full
              response = await userController.putUser(
                userName,
                firstName,
                lastName,
                _changePassword ? password : '',
                _changePassword ? password2 : '',
                _selectedDate!,
                _profileImage,
                id,
              );
              if (response == '') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyProfile(
                        id: id,
                      ),
                    ));
              } else {
                _showError(response);
              }
            }
          }
        },

        // Register button text
        child: Text.rich(
          TextSpan(
            text: _isDriver == false
                ? translation(context).saveChanges
                : translation(context).continueText,
            style: const TextStyle(
              fontSize: 18.0,
              color: Colors.white,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // Back button constructor
  Widget _botonBack() {
    return Row(
      children: [
        // Back button
        IconButton(
          icon: const Icon(Icons.arrow_back),
          // Click logic
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  // Profile picture selector constructor
  Widget _imageSelector() {
    return GestureDetector(
      // Image selection logic
      onTap: () async {
        XFile? image =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        setState(() {
          _profileImage = image;
        });
      },
      // Field where profile picture is shown
      child: CircleAvatar(
        radius: 75.0,
        backgroundColor: const Color.fromARGB(255, 162, 162, 162),
        backgroundImage: NetworkImage(logedUser!.pfp),
        // Set profile picture
        child: Stack(
          children: [
            if (_profileImage != null)
              // Show selected profile picture
              ClipOval(
                child: Image.file(
                  File(_profileImage!.path),
                  fit: BoxFit.cover,
                  width: 150.0,
                  height: 150.0,
                ),
              ),
            // Bottom left corner edit icon
            Positioned(
              bottom: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Icon(
                  size: 45,
                  Icons.circle,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const Positioned(
              bottom: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(6.5),
                child: Icon(
                  size: 30,
                  Icons.edit,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Driver selecting slider constructor
  Widget _buildDriverSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // "Do you want to be a driver?" text
        Flexible(
          child: Text.rich(TextSpan(
            text: _isDriver == false
                ? translation(context).wantToBeDriver
                : translation(context).wantToStopBeingDriver,
            style: const TextStyle(
              fontSize: 18.0,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          )),
        ),
        // Slider to choose whether to be a driver
        Switch(
          activeColor: Colors.white,
          activeTrackColor: Colors.lightGreenAccent[700],
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[500],
          value: _isDriver,
          onChanged: (value) {
            setState(() {
              _isDriver = value;
              _isDataLoaded = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPasswordChanger() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // "Do you want to change password?" text
        const Flexible(
          child: Text.rich(TextSpan(
            text: '¿Quieres cambiar la contraseña?',
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          )),
        ),
        // Slider to choose whether to change password
        Switch(
          activeColor: Colors.white,
          activeTrackColor: Colors.lightGreenAccent[700],
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[500],
          value: _changePassword,
          onChanged: (value) {
            setState(() {
              _changePassword = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildChangePasswordFieldsSelector() {
    return Visibility(
      visible:
          _changePassword, // Controls visibility based on _changePassword's value
      child: Column(
        children: [
          // Password text field
          _buildPasswordSelector(
              _passwordController, translation(context).password),
          const SizedBox(height: 10.0),

          // Confirm password text field
          _buildPasswordSelector(
              _confirmPasswordController, translation(context).confirmPassword),
          const SizedBox(height: 2.0),
        ],
      ),
    );
  }

  // Driver specific fields selector
  Widget _buildDriverFieldsSelector() {
    return Visibility(
      visible: _isDriver, // Controls visibility based on _isDriver's value
      child: Column(
        children: [
          // Max capacity field
          _buildNumberField(
            _capacidadMaximaDelVehiculoController,
            translation(context).maxVehicleCapacity,
          ),
          const SizedBox(height: 10.0),

          // IBAN text field
          _buildTextField(_ibanController, 'IBAN'),
        ],
      ),
    );
  }

  // Name selection constructor
  Widget _buildNameSelector() {
    return Row(
      children: [
        // First name text field
        Expanded(
            child: _buildTextField(
                _firstNameController, translation(context).firstName)),
        const SizedBox(width: 16),

        // Last name text field
        Expanded(
            child: _buildTextField(
                _lastNameController, translation(context).lastName)),
      ],
    );
  }

  // Extra functions

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

  // Date selector
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool isValidIBAN(String iban) {
    final ibanRegex = RegExp(r'^[a-zA-Z]{2}\w{22}$');
    // Check if the string matches the regular expression
    return ibanRegex.hasMatch(iban);
  }

  Future<User?> _getUserInfo() async {
    int id = await userController.usersSelf();
    return await userController.getUserInformation(id);
  }

  Future<Driver?> _getDriverInfo() async {
    int id = await userController.usersSelf();
    return await userController.getDriverInformation(id);
  }

  Widget _buildEraseButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      ),
      // Actions when the button is pressed
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                translation(context).warning,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              content: Text(
                translation(context).confirmDeleteProfile,
                style: const TextStyle(fontSize: 15),
              ),
              actions: [
                TextButton(
                  child: Text(
                    translation(context).yes,
                    style: const TextStyle(
                      fontSize: 20.0,
                      color: Colors.red,
                    ),
                  ),
                  onPressed: () async {
                    int id = await userController.usersSelf();
                    userController.deleteUser(id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LogIn(),
                      ),
                    );
                  },
                ),
                TextButton(
                  child: Text(
                    translation(context).no,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Text.rich(
        TextSpan(
          text: translation(context).deleteProfile,
          style: const TextStyle(
            fontSize: 18.0,
            color: Colors.white,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
