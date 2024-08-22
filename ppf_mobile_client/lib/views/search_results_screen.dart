import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ppf_mobile_client/Controllers/RouteController.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/Models/BasicRoute.dart';
import 'package:ppf_mobile_client/Models/Coment.dart';
import 'package:ppf_mobile_client/Models/Users.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/global_widgets/NavigationBar.dart';
import 'package:ppf_mobile_client/views/map_preview_screen.dart';
import 'package:ppf_mobile_client/views/route-order-selection-screen.dart';
import 'package:ppf_mobile_client/views/search_screen.dart';

class SearchResults extends StatefulWidget {
  final String departure;
  final String destination;
  final DateTime date;
  final String freeSpaces;
  final double departureLat;
  final double departureLon;
  final double destinationLat;
  final double destinationLon;
  final String? order;

  const SearchResults(
      {Key? key,
      required this.departure,
      required this.destination,
      required this.date,
      required this.freeSpaces,
      required this.departureLat,
      required this.departureLon,
      required this.destinationLat,
      required this.destinationLon,
      this.order})
      : super(key: key);

  @override
  _SearchResultsState createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<SimpleRoute> routes = [];
  final TextEditingController _freeSpacesController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int page = 1;
  bool isLoading = false;
  String order = 'OrderOption.time';

  void _openEndDrawer() {
    _scaffoldKey.currentState!.openEndDrawer();
  }

  @override
  void initState() {
    super.initState();
    _departureController.text = widget.departure;
    _destinationController.text = widget.destination;
    _freeSpacesController.text = widget.freeSpaces;
    _selectedDate = widget.date;
    order = widget.order ?? 'OrderOption.time';
    getRoutes();
  }

  Future<void> getRoutes() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<SimpleRoute> routesAux = await routeController.getRoutes(
        widget.departureLat,
        widget.departureLon,
        widget.destinationLat,
        widget.destinationLon,
        _selectedDate,
        _freeSpacesController.text,
        10,
        page,
      );

      setState(() {
        routes += routesAux;
        orderRoutes();
        page++;
      });
    } catch (e) {
      debugPrint('Error fetching routes: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void orderRoutes() {
    if (order == 'OrderOption.time') {
      routes.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    } else if (order == 'OrderOption.price') {
      routes.sort((a, b) => a.price.compareTo(b.price));
    } else if (order == 'OrderOption.departureDistance') {
      routes.sort((a, b) => a.distance.compareTo(b.distanceOrigin));
    } else if (order == 'OrderOption.destinationDistance') {
      routes.sort((a, b) => a.distance.compareTo(b.distanceDestination));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      body: Column(
        children: [
          const SizedBox(height: 40),
          SizedBox(
            height: screenHeight * 0.07,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 0.065),
                Flexible(
                  child: Container(
                      width: screenWidth * 0.87,
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                          width: 1,
                        ),
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios_new,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  size: 16),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) {
                                    return SearchScreen(
                                      departure: widget.departure,
                                      destination: widget.destination,
                                      date: widget.date,
                                      freeSpaces: widget.freeSpaces.toString(),
                                    );
                                  }),
                                );
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  RichText(
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: _departureController.text,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontSize: 16,
                                              ),
                                        ),
                                        TextSpan(
                                          text: ' -> ',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontSize: 16,
                                              ),
                                        ),
                                        TextSpan(
                                          text: _destinationController.text,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontSize: 16,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: DateFormat('dd/MM/yyyy')
                                              .format(widget.date),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSecondaryContainer),
                                        ),
                                        TextSpan(
                                          text: widget.freeSpaces == 1
                                              ? ', ${widget.freeSpaces} ${translation(context).pasajero}'
                                              : ', ${widget.freeSpaces} ${translation(context).pasajeros}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSecondaryContainer),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: translation(context).ordenar,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) {
                                            return OrderSelection(
                                              departure: widget.departure,
                                              destination: widget.destination,
                                              date: widget.date,
                                              freeSpaces: widget.freeSpaces,
                                              departureLat: widget.departureLat,
                                              departureLon: widget.departureLon,
                                              destinationLat:
                                                  widget.destinationLat,
                                              destinationLon:
                                                  widget.destinationLon,
                                              order: order,
                                            );
                                          }),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10)
                          ])),
                )
              ],
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent &&
                    !isLoading) {
                  getRoutes();
                }
                return false;
              },
              child: routes.isEmpty
                  ? Center(
                      child: Text(
                        translation(context).noRutasEncontradas,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: routes.length,
                      itemBuilder: (context, index) {
                        SimpleRoute route = routes[index];
                        DateTime arrivalTime = route.departureTime
                            .add(Duration(seconds: (route.duration).toInt()));
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapPreview(
                                    routeOG: route,
                                    seats: route.freeSeats.toString()),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 26, right: 26, top: 8, bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.background,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('HH:mm')
                                                .format(route.departureTime),
                                            style: Theme.of(context)
                                                .textTheme
                                                .displaySmall,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '${(route.duration / 3600).floor()}h${((route.duration % 3600) / 60).round()}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(fontSize: 12),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            DateFormat('HH:mm')
                                                .format(arrivalTime),
                                            style: Theme.of(context)
                                                .textTheme
                                                .displaySmall,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const SizedBox(width: 30, height: 3),
                                          Icon(Icons.circle_outlined,
                                              size: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                          Container(
                                              width: 4,
                                              height: 40,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                          Icon(Icons.circle_outlined,
                                              size: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                        ],
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(route.originAlias,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .displaySmall),
                                            Row(
                                              children: [
                                                route.distanceOrigin < 3
                                                    ? Stack(
                                                        children: [
                                                          Positioned(
                                                              child: Icon(
                                                                  Icons.circle,
                                                                  size: 24,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .secondary)),
                                                          Positioned(
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Icon(
                                                                      Icons
                                                                          .directions_walk_outlined,
                                                                      size: 18,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .background))),
                                                        ],
                                                      )
                                                    : Stack(
                                                        children: [
                                                          const Positioned(
                                                              child: Icon(
                                                                  Icons.circle,
                                                                  size: 24,
                                                                  color: Colors
                                                                      .grey)),
                                                          Positioned(
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Icon(
                                                                      Icons
                                                                          .directions_walk_outlined,
                                                                      size: 18,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .background))),
                                                        ],
                                                      ),
                                                route.distanceOrigin >= 3 &&
                                                        route.distanceOrigin <
                                                            15
                                                    ? Stack(
                                                        children: [
                                                          const Positioned(
                                                              child: Icon(
                                                                  Icons.circle,
                                                                  size: 24,
                                                                  color: Colors
                                                                      .amber)),
                                                          Positioned(
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Icon(
                                                                      Icons
                                                                          .directions_walk_outlined,
                                                                      size: 18,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .background))),
                                                        ],
                                                      )
                                                    : Stack(
                                                        children: [
                                                          const Positioned(
                                                              child: Icon(
                                                                  Icons.circle,
                                                                  size: 24,
                                                                  color: Colors
                                                                      .grey)),
                                                          Positioned(
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Icon(
                                                                      Icons
                                                                          .directions_walk_outlined,
                                                                      size: 18,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .background))),
                                                        ],
                                                      ),
                                                route.distanceOrigin >= 15
                                                    ? Stack(
                                                        children: [
                                                          const Positioned(
                                                              child: Icon(
                                                                  Icons.circle,
                                                                  size: 24,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          180,
                                                                          81,
                                                                          0))),
                                                          Positioned(
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Icon(
                                                                      Icons
                                                                          .directions_walk_outlined,
                                                                      size: 18,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .background))),
                                                        ],
                                                      )
                                                    : Stack(
                                                        children: [
                                                          const Positioned(
                                                              child: Icon(
                                                                  Icons.circle,
                                                                  size: 24,
                                                                  color: Colors
                                                                      .grey)),
                                                          Positioned(
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Icon(
                                                                      Icons
                                                                          .directions_walk_outlined,
                                                                      size: 18,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .background))),
                                                        ],
                                                      ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(route.destinationAlias,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .displaySmall),
                                            Row(
                                              children: [
                                                route.distanceDestination < 3
                                                    ? Stack(
                                                        children: [
                                                          Positioned(
                                                              child: Icon(
                                                                  Icons.circle,
                                                                  size: 24,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .secondary)),
                                                          Positioned(
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Icon(
                                                                      Icons
                                                                          .directions_walk_outlined,
                                                                      size: 18,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .background))),
                                                        ],
                                                      )
                                                    : Stack(
                                                        children: [
                                                          const Positioned(
                                                              child: Icon(
                                                                  Icons.circle,
                                                                  size: 24,
                                                                  color: Colors
                                                                      .grey)),
                                                          Positioned(
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Icon(
                                                                      Icons
                                                                          .directions_walk_outlined,
                                                                      size: 18,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .background))),
                                                        ],
                                                      ),
                                                route.distanceDestination >=
                                                            3 &&
                                                        route.distanceDestination <
                                                            15
                                                    ? Stack(
                                                        children: [
                                                          const Positioned(
                                                              child: Icon(
                                                                  Icons.circle,
                                                                  size: 24,
                                                                  color: Colors
                                                                      .amber)),
                                                          Positioned(
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Icon(
                                                                      Icons
                                                                          .directions_walk_outlined,
                                                                      size: 18,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .background))),
                                                        ],
                                                      )
                                                    : Stack(
                                                        children: [
                                                          const Positioned(
                                                              child: Icon(
                                                                  Icons.circle,
                                                                  size: 24,
                                                                  color: Colors
                                                                      .grey)),
                                                          Positioned(
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Icon(
                                                                      Icons
                                                                          .directions_walk_outlined,
                                                                      size: 18,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .background))),
                                                        ],
                                                      ),
                                                route.distanceDestination >= 15
                                                    ? Stack(
                                                        children: [
                                                          const Positioned(
                                                              child: Icon(
                                                                  Icons.circle,
                                                                  size: 24,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          180,
                                                                          81,
                                                                          0))),
                                                          Positioned(
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Icon(
                                                                      Icons
                                                                          .directions_walk_outlined,
                                                                      size: 18,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .background))),
                                                        ],
                                                      )
                                                    : Stack(
                                                        children: [
                                                          const Positioned(
                                                              child: Icon(
                                                                  Icons.circle,
                                                                  size: 24,
                                                                  color: Colors
                                                                      .grey)),
                                                          Positioned(
                                                              child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Icon(
                                                                      Icons
                                                                          .directions_walk_outlined,
                                                                      size: 18,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .background))),
                                                        ],
                                                      ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Text('${route.price.toStringAsFixed(2)}€',
                                          style: Theme.of(context)
                                              .textTheme
                                              .displaySmall
                                              ?.copyWith(fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          FutureBuilder(
                                              future:
                                                  _getUserPfp(route.driverId),
                                              builder: (context, snapshot) {
                                                return CircleAvatar(
                                                  backgroundImage: NetworkImage(
                                                      snapshot.data ?? ''),
                                                  radius: 20,
                                                );
                                              }),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(route.driverName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .displaySmall
                                                      ?.copyWith(fontSize: 16)),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star,
                                                      color: Colors.amber,
                                                      size: 16),
                                                  FutureBuilder(
                                                      future: _getUserValuation(
                                                          route.driverId),
                                                      builder:
                                                          (context, snapshot) {
                                                        return Text(
                                                          snapshot.data ??
                                                              '0.0',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                      fontSize:
                                                                          12),
                                                        );
                                                      }),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Expanded(child: SizedBox(width: 2)),
                                      Icon(Icons.person,
                                          size: 20,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                      const SizedBox(width: 5),
                                      Text('${route.freeSeats}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Bar(selectedIndex: 0),
    );
  }

  Future<String?> _getUserValuation(int id) async {
    List<Comment> reviews = await UserController().getUserCommentsId(id);
    Map<int, User> userMap = {};
    double totalRating = 0.0;
    for (var comment in reviews) {
      User? user = await UserController().getUserInformation(comment.giver);
      if (user != null) {
        userMap[comment.giver] = user;
      }
    }

    for (var review in reviews) {
      totalRating += review.rating;
    }
    double averageRating =
        reviews.isNotEmpty ? totalRating / reviews.length : 0.0;
    return averageRating.toString();
  }

  Future<String?> _getUserPfp(int id) async {
    User? driver = await UserController().getUserInformation(id);
    return driver?.pfp;
  }

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
}
