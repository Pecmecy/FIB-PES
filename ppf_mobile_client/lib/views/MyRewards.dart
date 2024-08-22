import 'package:flutter/material.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/Models/Achivement.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/global_widgets/MyProfileNavigation.dart';
import 'package:ppf_mobile_client/global_widgets/NavigationBar.dart';

class MyRewards extends StatefulWidget {
  final int id;
  final bool isLoggedUser;

  const MyRewards({super.key, required this.id, required this.isLoggedUser});

  @override
  _MyRewardsState createState() => _MyRewardsState();
}

class _MyRewardsState extends State<MyRewards> {
  late List<Achievement> achievements;

  @override
  void initState() {
    super.initState();
    getAchievements();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeAchievements();
  }

  void initializeAchievements() {
    achievements = [
      Achievement(
        title: translation(context).primeraVez,
        description: translation(context).primeraVezDesc,
        icon: Icons.directions,
        achieved: false,
        date: 'N/A',
      ),
      Achievement(
        title: translation(context).finalFeliz,
        description: translation(context).finalFelizDesc,
        icon: Icons.flag,
        achieved: false,
        date: 'N/A',
      ),
      Achievement(
        title: translation(context).infiltRuta,
        description: translation(context).infiltRutaDesc,
        icon: Icons.group,
        achieved: false,
        date: 'N/A',
      ),
      Achievement(
        title: translation(context).criticoEstelar,
        description: translation(context).criticoEstelarDesc,
        icon: Icons.star,
        achieved: false,
        date: 'N/A',
      ),
      Achievement(
        title: translation(context).camaleon,
        description: translation(context).camaleonDesc,
        icon: Icons.person,
        achieved: false,
        date: 'N/A',
      ),
      Achievement(
        title: translation(context).exploradorDecenal,
        description: translation(context).exploradorDecenalDesc,
        icon: Icons.explore,
        achieved: false,
        date: 'N/A',
      ),
      Achievement(
        title: translation(context).nomadaIntrepido,
        description: translation(context).nomadaIntrepidoDesc,
        icon: Icons.alt_route,
        achieved: false,
        date: 'N/A',
      ),
      Achievement(
        title: translation(context).arquitectoViajero,
        description: translation(context).arquitectoViajeroDesc,
        icon: Icons.design_services,
        achieved: false,
        date: 'N/A',
      ),
      Achievement(
        title: translation(context).maestroDeRutas,
        description: translation(context).maestroDeRutasDesc,
        icon: Icons.map,
        achieved: false,
        date: 'N/A',
      ),
    ];
  }

  void getAchievements() async {
    List<SimpleAchievement> auxAchievements =
        await UserController().getUserAchievements(widget.id);
    setState(() {
      for (int i = 0; i < auxAchievements.length; i++) {
        achievements[i].achieved = auxAchievements[i].achieved;
        achievements[i].date = auxAchievements[i].date ?? 'N/A';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyProfileNavigation(
          selectedIndex: 2, id: widget.id, isLoggedUser: widget.isLoggedUser),
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          return AchievementItem(achievement: achievements[index]);
        },
      ),
      bottomNavigationBar: Bar(selectedIndex: widget.isLoggedUser ? 4 : 0),
    );
  }
}

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  bool achieved;
  String date;

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.achieved,
    required this.date,
  });
}

class AchievementItem extends StatefulWidget {
  final Achievement achievement;

  const AchievementItem({Key? key, required this.achievement})
      : super(key: key);

  @override
  _AchievementItemState createState() => _AchievementItemState();
}

class _AchievementItemState extends State<AchievementItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.achievement.icon,
                    size: 40,
                    color: widget.achievement.achieved
                        ? Colors.black
                        : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.achievement.title,
                    style: TextStyle(
                      color: widget.achievement.achieved
                          ? Colors.black
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 10),
                Text(
                  '${translation(context).fechaObtencion}: ${widget.achievement.date}',
                  style: TextStyle(
                    color: widget.achievement.achieved
                        ? Colors.black
                        : Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.achievement.description,
                  style: TextStyle(
                    color: widget.achievement.achieved
                        ? Colors.black
                        : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
