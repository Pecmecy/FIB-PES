import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/views/driver_information.dart';
import 'package:ppf_mobile_client/views/search_screen.dart';

//Register Screen initialization
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

//Register screen
class _RegistrationScreenState extends State<RegisterScreen> {
  //Register variables
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _capacidadMaximaDelVehiculoController =
      TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  var hide1 = true;
  DateTime? _selectedDate;
  XFile? _profileImage;
  bool _isDriver = false;

  //Register screen components
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        leading: _botonBack(),
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      //SingleChildScrollView to deal with overflow when opening keyboard
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        //Column to show components from top to bottom
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16.0),
            //Profile picture
            _imageSelector(),
            const SizedBox(height: 10.0),

            //Email text field
            _buildTextField(
                _emailController, translation(context).correoElectronico),
            const SizedBox(height: 10.0),

            //Username text field
            _buildTextField(
                _userNameController, translation(context).nombreUsuario),
            const SizedBox(height: 10.0),

            //Name text field
            _buildNameSelector(),
            const SizedBox(height: 10.0),

            //Date selection field
            _buildDateSelector(),
            const SizedBox(height: 10.0),

            //Password text field
            _buildPasswordSelector(
                _passwordController, translation(context).contrasena),
            const SizedBox(height: 10.0),

            //Confirm password text field
            _buildPasswordSelector(_confirmPasswordController,
                translation(context).repetirContrasena),
            const SizedBox(height: 2.0),

            //Choosing to be or not to be (a driver :D)
            _buildDriverSelector(),
            const SizedBox(height: 10.0),

            //Driver specific fields, only shown if _isDriver is true
            _buildDriverFieldsSelector(),
            const SizedBox(height: 20.0),

            //Register button
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  //Constructors

  //Regular text field
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
            color: Theme.of(context).colorScheme.background),
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
        ));
  }

  //Password text field
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
            color: Theme.of(context).colorScheme.background),
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
            //Hide/Show password button
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
        ));
  }

  //Number selection text field
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
            color: Theme.of(context).colorScheme.background),
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
        ));
  }

  //Date selection field
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
          color: Theme.of(context).colorScheme.background),
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
                  text: translation(context).fechaNacimiento,
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

  //Register button
  Widget _buildRegisterButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      ),

      //Actions when the button is pressed
      onPressed: () async {
        //Register variables
        String userName = _userNameController.text;
        String firstName = _firstNameController.text;
        String lastName = _lastNameController.text;
        String email = _emailController.text;
        String password = _passwordController.text;
        String password2 = _confirmPasswordController.text;
        String dni = _dniController.text;
        String capacidad = _capacidadMaximaDelVehiculoController.text;
        String iban = _ibanController.text;
        String response;

        //Show error message when passwords are different
        if (password != password2) {
          _showError(translation(context).errorRepetirContrasena);
        }

        //Show error message if email is not valid
        else if (!EmailValidator.validate(email)) {
          _showError(translation(context).errorCorreoElectronico);
        }

        //Password and email are valid
        else {
          //Driver case
          if (_isDriver) {
            //Show error message if one of the fields is empty
            if (userName.isEmpty ||
                email.isEmpty ||
                _selectedDate == null ||
                password.isEmpty ||
                password2.isEmpty ||
                dni.isEmpty ||
                capacidad.isEmpty ||
                iban.isEmpty) {
              _showError(translation(context).errorCompletarCampos);
            }

            //Check if the DNI is valid
            else if (!isValidDNI(dni) && !isValidNIE(dni)) {
              _showError(translation(context).errorDniNie);
            } else if (!isValidIBAN(iban)) {
              _showError(translation(context).errorIban);
            }

            //Register driver if all fields are full
            else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DriverInformation(
                            username: userName,
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            password: password,
                            password2: password2,
                            selectedDate: _selectedDate,
                            dni: dni,
                            capacidad: capacidad,
                            iban: iban,
                            profileImage: _profileImage,
                          )));
            }
          }
          //Non driver case
          else {
            //Show error message if one of the fields is empty
            if (userName.isEmpty ||
                email.isEmpty ||
                _selectedDate == null ||
                password.isEmpty ||
                password2.isEmpty) {
              _showError(translation(context).errorCompletarCampos);
            }

            //Register non driver if all fields are full
            else {
              response = await userController.registerUser(
                userName,
                firstName,
                lastName,
                email,
                password,
                password2,
                _selectedDate,
              );

              if (response != translation(context).errorRegistro) {
                if (_profileImage != null) {
                  userController.putUserAvatar(
                      _profileImage!, int.parse(response));
                }
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SearchScreen()));
              } else {
                _showError(response);
              }
            }
          }
        }
      },

      //Register button text
      child: Text.rich(
        TextSpan(
            text: translation(context).registrarse,
            style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }

  //Back button constructor
  Widget _botonBack() {
    return Row(
      children: [
        //Back button
        IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.primary,
          ),
          //Click logic
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  //Profile picture selector constructor
  Widget _imageSelector() {
    return GestureDetector(
      //Image selection logic
      onTap: () async {
        XFile? image =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        setState(() {
          _profileImage = image;
        });
      },
      //Field where profile picture is shown
      child: CircleAvatar(
        radius: 75.0,
        backgroundColor: Colors.purple,
        //Set profile picture
        child: Stack(children: [
          _profileImage == null
              //Show icon if no profile picture has been selected
              ? Icon(
                  Icons.person,
                  size: 150.0,
                  color: Theme.of(context).colorScheme.background,
                )
              //Show selected profile picture
              : ClipOval(
                  child: Image.file(
                    File(_profileImage!.path),
                    fit: BoxFit.cover,
                    width: 150.0,
                    height: 150.0,
                  ),
                ),
          //Bottom left corner edit icon
          Positioned(
            bottom: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Icon(
                size: 45,
                Icons.circle,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(6.5),
              child: Icon(
                size: 30,
                Icons.edit,
                color: Theme.of(context).colorScheme.background,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  //Driver selecting slider constructor
  Widget _buildDriverSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        //"Do you want to be a driver?" text
        Text.rich(TextSpan(
          text: translation(context).quieresSerConductor,
          style: Theme.of(context).textTheme.bodyMedium,
        )),
        //Slider to choose wether to be a driver
        Switch(
          activeColor: Theme.of(context).colorScheme.onPrimaryContainer,
          activeTrackColor: Theme.of(context).colorScheme.secondary,
          inactiveThumbColor: Theme.of(context).colorScheme.onPrimaryContainer,
          inactiveTrackColor:
              Theme.of(context).colorScheme.onSecondaryContainer,
          trackOutlineColor: MaterialStateProperty.resolveWith(
            (states) => Theme.of(context).colorScheme.shadow,
          ),
          value: _isDriver,
          onChanged: (value) {
            setState(() {
              _isDriver = value;
            });
          },
        ),
      ],
    );
  }

  //Driver specific fields selector
  Widget _buildDriverFieldsSelector() {
    return Visibility(
      visible: _isDriver, //Controls visibility based on _isDriver's value
      child: Column(
        children: [
          //DNI text field
          _buildTextField(_dniController, translation(context).dniNie),
          const SizedBox(height: 10.0),

          //Max capacity field
          _buildNumberField(_capacidadMaximaDelVehiculoController,
              translation(context).autonomiaVehiculo),
          const SizedBox(height: 10.0),

          //IBAN text field
          _buildTextField(_ibanController, translation(context).iban),
        ],
      ),
    );
  }

  //Name selection constructor
  Widget _buildNameSelector() {
    return Row(
      children: [
        //First name text field
        Expanded(
            child: _buildTextField(
                _firstNameController, translation(context).nombre)),
        const SizedBox(width: 16),

        //Last name text field
        Expanded(
            child: _buildTextField(
                _lastNameController, translation(context).apellidos))
      ],
    );
  }

  //Extra functions

  //Show errors
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

  //Date selector
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      helpText: translation(context).fechaNacimiento,
      cancelText: translation(context).cancelar,
      confirmText: translation(context).seleccionar,
      errorFormatText: translation(context).errorFormatoFecha,
      errorInvalidText: translation(context).errorFechaInvalida,
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

  //Check if DNI is valid
  bool isValidDNI(String dni) {
    // Regular expression for validating a string with 8 numbers followed by a letter
    final dniRegex = RegExp(r'^\d{8}[a-zA-Z]$');

    // Check if the string matches the regular expression
    return dniRegex.hasMatch(dni);
  }

  //Check if NIE is valid
  bool isValidNIE(String dni) {
    // Regular expression for validating a string with 8 numbers followed by a letter
    final dniRegex = RegExp(r'^[a-zA-Z]\d{7}[a-zA-Z]$');

    // Check if the string matches the regular expression
    return dniRegex.hasMatch(dni);
  }

  bool isValidIBAN(String iban) {
    final ibanRegex = RegExp(r'^[a-zA-Z]{2}\w{22}$');

    // Check if the string matches the regular expression
    return ibanRegex.hasMatch(iban);
  }
}
