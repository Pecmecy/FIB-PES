import 'package:flutter/material.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/views/MyGrade.dart';
import 'package:ppf_mobile_client/views/MyRewards.dart';
import 'package:ppf_mobile_client/views/my_profile.dart';

class MyProfileNavigation extends StatelessWidget
    implements PreferredSizeWidget {
  final int selectedIndex;
  final int id;
  final bool isLoggedUser;
  const MyProfileNavigation(
      {super.key,
      required this.selectedIndex,
      required this.id,
      required this.isLoggedUser});

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MyProfile(
                    id: id,
                  )),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MyGrade(
                    id: id,
                    isLoggedUser: isLoggedUser,
                  )),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MyRewards(
                    id: id,
                    isLoggedUser: isLoggedUser,
                  )),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: preferredSize.height,
      child: Padding(
        padding: const EdgeInsets.only(
            top:
                20.0), // Adjust the top padding to avoid overlap with system status bar
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => _onItemTapped(context, 0),
              child: Text(
                isLoggedUser ? translation(context).myProfile : 'Perfil',
                style: TextStyle(
                  color: selectedIndex == 0
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _onItemTapped(context, 1),
              child: Text(
                translation(context).ratings,
                style: TextStyle(
                  color: selectedIndex == 1
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _onItemTapped(context, 2),
              child: Text(
                translation(context).achievements,
                style: TextStyle(
                  color: selectedIndex == 2
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 30);
}
