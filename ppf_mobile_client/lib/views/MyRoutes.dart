import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:ppf_mobile_client/Controllers/RouteController.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/Models/BasicRoute.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/global_widgets/NavigationBar.dart';
import 'package:ppf_mobile_client/views/map_following.dart';
import 'package:ppf_mobile_client/views/map_preview_screen.dart';
import 'package:ppf_mobile_client/views/pantalla-chat.dart';
import 'package:ppf_mobile_client/views/search_screen.dart';

class MyRoutes extends StatefulWidget {
  const MyRoutes({super.key});

  @override
  _MyRoutesState createState() => _MyRoutesState();
}

class _MyRoutesState extends State<MyRoutes>
    with SingleTickerProviderStateMixin {
  List<SimpleRoute> activeRoutes = [];
  List<SimpleRoute> finalizedRoutes = [];
  int id = 0;
  int currentUserId = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    getidAndRoutes();
  }

  void getidAndRoutes() async {
    id = await userController.usersSelf();
    currentUserId = await UserController().usersSelf();
    getroutes();
  }

  void getroutes() async {
    List<SimpleRoute> auxRoutes = await routeController.getUserRoutes(id);
    setState(() {
      activeRoutes = auxRoutes.where((route) => !route.finalized).toList();
      finalizedRoutes = auxRoutes.where((route) => route.finalized).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.shadow,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorWeight: 4.0,
                tabs: [
                  Tab(text: translation(context).active),
                  Tab(text: translation(context).finished),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RouteList(
                    routes: activeRoutes,
                    currentUserId: currentUserId,
                    emptyMessage: "Ahora mismo no estás unido a ninguna ruta.",
                  ),
                  RouteList(
                    routes: finalizedRoutes,
                    currentUserId: currentUserId,
                    emptyMessage: "No tienes rutas finalizadas.",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Bar(selectedIndex: 1),
    );
  }
}

class RouteList extends StatelessWidget {
  final List<SimpleRoute> routes;
  final int currentUserId;
  final String emptyMessage;

  const RouteList(
      {super.key,
      required this.routes,
      required this.currentUserId,
      required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 18.0),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        SimpleRoute route = routes[index];
        return RouteCard(
          route: route,
          isDriver: route.driverId == currentUserId,
          userId: currentUserId,
        );
      },
    );
  }
}

class RouteCard extends StatelessWidget {
  final SimpleRoute route;
  final bool isDriver;
  final int userId;

  const RouteCard({
    super.key,
    required this.route,
    required this.isDriver,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPreview(
                      routeOG: route,
                      seats: route.freeSeats.toString(),
                    ),
                  ),
                );
              },
              child: Text(
                '${route.originAlias} -> ${route.destinationAlias}',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.normal,
                  color: /*isDriver
                      ? Theme.of(context).colorScheme.primary
                      :*/
                      Colors.black, // Cambiar el color si es conductor
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd-MM-yyyy HH:mm').format(route.departureTime),
              style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isDriver)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car,
                            color: Colors.white, size: 16.0),
                        const SizedBox(width: 4.0),
                        Text(
                          localizations!.driver,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.map),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () async {
                    int userId = await userController.usersSelf();
                    if (route.departureTime.isBefore(DateTime.now()) &&
                        !route.finalized &&
                        (route.passengers.contains(userId) ||
                            route.driverId == userId)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapFollowing(
                            routeId: route.id,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations!.cannotFollowRoute),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chat),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          routeId: route.id,
                          userId: userId,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  color: Colors.red,
                  onPressed: () async {
                    String result = await routeController.leaveRoute(route.id);
                    if (result == '') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations!.errorLeavingRoute),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
