import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/Models/Driver.dart';
import 'package:ppf_mobile_client/Models/Users.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/global_widgets/MyProfileNavigation.dart';
import 'package:ppf_mobile_client/global_widgets/NavigationBar.dart';
import 'package:ppf_mobile_client/views/edit_user.dart';
import 'package:ppf_mobile_client/views/login_screen.dart';

class MyProfile extends StatefulWidget {
  final int id;
  const MyProfile({super.key, required this.id});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  int loggedUserId = 0;
  int sliderState = 0;
  Future<List<dynamic>>? _dataFuture;
  User? logedUser;
  Driver? driver;
  List<String> driverChargerTypes = [
    'Mennekes',
    'Tesla',
    'Schuko',
    'ChadeMO',
    'CCS Combo2',
  ];

  List<String> driverPreferences = [];

  Map<String, String> preferencesNames = {};
  Map<String, String> preferencesIcons = {};

  @override
  void initState() {
    super.initState();
    _dataFuture =
        Future.wait([_getUserInfo(), _getDriverInfo(), _getSelfUserId()]);
  }

  @override
  Widget build(BuildContext context) {
    _initializePreferences(context);

    return FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            logedUser = snapshot.data![0];
            driver = snapshot.data![1];
            if (driver != null) {
              for (var i in driver!.preferences.keys) {
                if (!driverPreferences.contains(preferencesNames[i]!) &&
                    driver!.preferences[i]!) {
                  driverPreferences.add(preferencesNames[i]!);
                }
              }
            }
            loggedUserId = snapshot.data![2];
            if (sliderState == 0) {
              return Scaffold(
                resizeToAvoidBottomInset: true,
                appBar: MyProfileNavigation(
                    selectedIndex: 0,
                    id: widget.id,
                    isLoggedUser: loggedUserId == widget.id),
                body: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SingleChildScrollView(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                    height: MediaQuery.of(context).size.width *
                                        0.2),
                                _buildProfileImage(),
                                const SizedBox(height: 20),
                                _buildTextField(context, logedUser!.username),
                                const SizedBox(height: 15),
                                _buildTextField(context, logedUser!.email),
                                const SizedBox(height: 15),
                                _buildTextField(context,
                                    '${logedUser!.firstName} ${logedUser!.lastName}'),
                                const SizedBox(height: 15),
                                _buildTextField(context,
                                    '${logedUser!.birthDate.day}/${logedUser!.birthDate.month}/${logedUser!.birthDate.year}'),
                                const SizedBox(height: 30),
                                _buildIsDriver(context),
                                const SizedBox(height: 15),
                                driver == null
                                    ? Container()
                                    : _buildDriverInformation(context),
                                const SizedBox(height: 15),
                                loggedUserId != widget.id
                                    ? Container()
                                    : _editProfileButton(context),
                                    const SizedBox(height: 15),
                                loggedUserId != widget.id
                                    ? Container()
                                    : _syncWithGoogleCalendarButton(context),
                                const SizedBox(height: 15),
                                loggedUserId != widget.id
                                    ? Container()
                                    : _cerrarSesionButton(context),
                              ],
                            )),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        alignment: Alignment.center,
                        height: 50,
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar:
                    Bar(selectedIndex: loggedUserId == widget.id ? 4 : 0),
              );
            } else {
              return Container();
            }
          }
        });
  }

  void _initializePreferences(BuildContext context) {
    preferencesNames = {
      'canNotTravelWithPets': translation(context).noPets,
      'listenToMusic': translation(context).listenToMusic,
      'noSmoking': translation(context).noSmoking,
      'talkTooMuch': translation(context).talkTooMuch,
    };

    preferencesIcons = {
      translation(context).noPets: 'assets/paw.png',
      translation(context).listenToMusic: 'assets/music.png',
      translation(context).noSmoking: 'assets/smoke.png',
      translation(context).talkTooMuch: 'assets/speak.png',
    };
  }

  Widget _cerrarSesionButton(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 250,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () async {
            const storage = FlutterSecureStorage();
            await storage.delete(key: 'token');
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LogIn()));
          },
          child: Text(
            translation(context).logOut,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          )),
    );
  }

  Widget _editProfileButton(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 250,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          onPressed: () {
            Navigator.push(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(
                builder: (context) => const EditUser(),
              ),
            );
          },
          child: Text(
            translation(context).editProfile,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          )),
    );
  }

  Widget _syncWithGoogleCalendarButton(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 250,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          onPressed: () async {
            userController.syncWithCalendar();
          },
          child: Text(
            translation(context).syncCalendar,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          )),
    );
  }

  Widget _buildDriverInformation(BuildContext context) {
    return Column(
      children: [
        _buildDriverChargers(context),
        const SizedBox(height: 20),
        _buildDriverPreferences(context),
      ],
    );
  }

  Container _buildDriverPreferences(BuildContext context) {
    return driverPreferences.isEmpty
        ? Container()
        : Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (var i in driverPreferences)
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Row(
                      children: [
                        ImageIcon(AssetImage(preferencesIcons[i]!)),
                        const SizedBox(width: 15.0),
                        Flexible(
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text.rich(TextSpan(
                                text: i,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ))),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
  }

  Container _buildDriverChargers(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < driver!.chargerTypes.length; i++)
            driver!.chargerTypes[i]
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      driverChargerTypes[i],
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  )
                : Container(),
        ],
      ),
    );
  }

  Widget _buildIsDriver(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          translation(context).isDriver,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        Icon(
          driver == null ? Icons.cancel : Icons.check_circle,
        ),
      ],
    );
  }

  Container _buildTextField(BuildContext context, String text) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: const TextStyle(
            fontSize: 18.0, color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  SizedBox _buildProfileImage() {
    return SizedBox(
      height: 150,
      width: 150,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
            radius: 30, backgroundImage: NetworkImage(logedUser!.pfp)),
      ),
    );
  }

  Future<User?> _getUserInfo() async {
    return await userController.getUserInformation(widget.id);
  }

  Future<Driver?> _getDriverInfo() async {
    return await userController.getDriverInformation(widget.id);
  }

  Future<int> _getSelfUserId() async {
    return await userController.usersSelf();
  }
}
