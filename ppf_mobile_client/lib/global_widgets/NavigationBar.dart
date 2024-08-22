import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ppf_mobile_client/views/login_screen.dart';
import 'package:ppf_mobile_client/views/my_profile.dart';
import 'package:ppf_mobile_client/views/search_screen.dart';
import 'package:ppf_mobile_client/views/route_creation_screen.dart';
import 'package:ppf_mobile_client/views/MyRoutes.dart';
import 'package:ppf_mobile_client/views/MyChats.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';

class Bar extends StatelessWidget {
  final int selectedIndex;

  const Bar({super.key, required this.selectedIndex});

  Future<void> _onItemTapped(BuildContext context, int index) async {
    if (index == selectedIndex) return;

    const storage = FlutterSecureStorage();
    bool isLoggedIn = await storage.containsKey(key: 'token');

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SearchScreen()),
        );
        break;
      case 1:
        if (isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyRoutes()),
          );
        } else {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const LogIn()));
        }
        break;
      case 2:
        if (isLoggedIn) {
          int userId = await userController.usersSelf();
          try {
            var driver = await userController.getDriverById(userId);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => RouteCreationScreen()),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No puedes crear una ruta sin ser conductor. Accede a editar tu perfil para configurarlo.',
                ),
              ),
            );
          }
        } else {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const LogIn()));
        }
        break;
      case 3:
        if (isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyChats()),
          );
        } else {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const LogIn()));
        }
        break;
      case 4:
        if (isLoggedIn) {
          int id = await userController.usersSelf();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MyProfile(
                      id: id,
                    )),
          );
        } else {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const LogIn()));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Buscar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car),
          label: 'Tus viajes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box),
          label: 'Publicar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Mensajes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSecondaryContainer,
      onTap: (index) => _onItemTapped(context, index),
    );
  }
}
