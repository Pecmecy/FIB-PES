import 'package:flutter/material.dart';
import 'package:ppf_mobile_client/Controllers/RouteController.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/Models/BasicRoute.dart';
import 'package:ppf_mobile_client/global_widgets/NavigationBar.dart';
import 'package:ppf_mobile_client/views/map_preview_screen.dart';
import 'package:ppf_mobile_client/views/pantalla-chat.dart';

class MyChats extends StatefulWidget {
  @override
  _MyChatsState createState() => _MyChatsState();
}

class _MyChatsState extends State<MyChats> {
  List<SimpleRoute> routes = [];
  int id = 0;

  void getidAndRoutes() async {
    id = await userController.usersSelf();
    getroutes();
  }

  void getroutes() async {
    List<SimpleRoute> auxRoutes = await routeController.getUserRoutes(id);
    setState(() {
      routes = auxRoutes.where((route) => !route.finalized).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    getidAndRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0), // Margen superior en blanco
        child: routes.isEmpty
            ? const Center(
                child: Text(
                  "Actualmente no estás en ninguna ruta, únete a una ruta para tener mensajes",
                  style: TextStyle(fontSize: 18.0),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  SimpleRoute route = routes[index];
                  return ChatCard(
                    route: route,
                    name: '${route.originAlias} -> ${route.destinationAlias}',
                    id: id,
                  );
                },
              ),
      ),
      bottomNavigationBar: const Bar(selectedIndex: 3),
    );
  }
}

class ChatCard extends StatelessWidget {
  final SimpleRoute route;
  final String name;

  final int id;

  const ChatCard(
      {super.key, required this.route, required this.name, required this.id});

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
          // Acción al presionar la tarjeta
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                routeId: route.id,
                userId: id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () {
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
