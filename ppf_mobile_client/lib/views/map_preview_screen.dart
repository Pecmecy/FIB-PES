import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ppf_mobile_client/Controllers/RouteController.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/Models/BasicRoute.dart';
import 'package:ppf_mobile_client/Models/Driver.dart';
import 'package:ppf_mobile_client/Models/Route.dart';
import 'package:ppf_mobile_client/Models/Users.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart'; // Make sure this import is correct
import 'package:ppf_mobile_client/global_widgets/NavigationBar.dart';
import 'package:ppf_mobile_client/views/RatingRoute.dart'; // Importa RatingPopup
import 'package:ppf_mobile_client/views/ReportUser.dart';
import 'package:ppf_mobile_client/views/my_profile.dart';
import 'package:ppf_mobile_client/views/pantalla_pago.dart';

class MapPreview extends StatefulWidget {
  final SimpleRoute routeOG;
  final String seats;

  const MapPreview({super.key, required this.routeOG, required this.seats});

  @override
  State<MapPreview> createState() => MapPreviewState();
}

class MapPreviewState extends State<MapPreview> {
  bool doneThisRoute = false;
  bool isDriver = false;
  bool routeFinalized = false;
  List<User> passengers = [];

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    await doneThis();
    await checkIfDriver();
    await checkIfRouteFinalized();
    await fetchPassengers();
    setState(() {});
  }

  Future<void> doneThis() async {
    doneThisRoute = await routeController.isUserinRoute(widget.routeOG.id);
  }

  Future<void> checkIfDriver() async {
    int userId = await userController.usersSelf();
    isDriver = widget.routeOG.driverId == userId;
  }

  Future<void> checkIfRouteFinalized() async {
    routeFinalized = widget.routeOG.finalized;
  }

  Future<void> fetchPassengers() async {
    if (isDriver && doneThisRoute) {
      passengers = await routeController.getRoutePassengers(widget.routeOG.id);
    }
  }

  Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> _markers = {};
  late List<LatLng> _polylineCoordinates = [];
  late MapRoute route = MapRoute.empty();
  late Driver driver = Driver.empty();

  String dirverValoration = '';

  List<String> driverPreferences = [];

  final Map<int, double> sizeOfPreferences = {
    0: 0.15,
    1: 0.2,
    2: 0.28,
    3: 0.33,
    4: 0.4,
  };

  final Map<String, String> preferencesNames = {
    'canNotTravelWithPets': 'noPets',
    'listenToMusic': 'listenToMusic',
    'noSmoking': 'noSmoking',
    'talkTooMuch': 'talkTooMuch',
  };

  final Map<String, String> preferencesIcons = {
    'noPets': 'assets/paw.png',
    'listenToMusic': 'assets/music.png',
    'noSmoking': 'assets/smoke.png',
    'talkTooMuch': 'assets/speak.png',
  };

  void _onMapCreated(GoogleMapController controller) async {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    } else {
      _controller = Completer();
      _controller.complete(controller);
    }
    route = await getRoute(widget.routeOG.id);
    driver = await getDriver();
    _markers.add(Marker(
      markerId: MarkerId(route.originAlias),
      position: LatLng(route.originLat, route.originLon),
      infoWindow: InfoWindow(title: route.originAlias),
    ));
    _markers.add(Marker(
      markerId: MarkerId(route.destinationAlias),
      position: LatLng(route.destinationLat, route.destinationLon),
      infoWindow: InfoWindow(title: route.destinationAlias),
    ));
    for (Map<String, dynamic> waypoint in route.waypoints) {
      _markers.add(Marker(
        markerId: MarkerId(waypoint['charger'].toString()),
        position: LatLng(waypoint['latitude'], waypoint['longitude']),
        infoWindow: const InfoWindow(
          title: 'Charger',
        ),
        onTap: () async {
          if (route.finalized) {
            _showReportCharger(context, waypoint['charger']);
          }
        },
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
      ));
    }
    List<PointLatLng> list = PolylinePoints().decodePolyline(route.polyline);

    _polylineCoordinates =
        list.map((point) => LatLng(point.latitude, point.longitude)).toList();
    _fitMarkersToBounds();
    setState(() {});
  }

  String getOrigin() {
    return route.originAlias;
  }

  String getDestination() {
    return route.destinationAlias;
  }

  Future<String> getDistanceToDeparture() async {
    Position position = await Geolocator.getCurrentPosition();
    double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          route.originLat,
          route.originLon,
        ) /
        1000;

    return distance.toStringAsFixed(3);
  }

  Future<String> getDistanceToDestination() async {
    Position position = await Geolocator.getCurrentPosition();
    double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          route.destinationLat,
          route.destinationLon,
        ) /
        1000;
    return distance.toStringAsFixed(3);
  }

  String formatTime(int hour, int min) {
    TimeOfDay timeOfDay = TimeOfDay(hour: hour, minute: min);

    String formattedTime =
        '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}';

    return formattedTime;
  }

  String getDepartureTime() {
    int hour = route.departureTime.hour;
    int min = route.departureTime.minute;
    return formatTime(hour, min);
  }

  String getArrivalTime() {
    int departureHour = route.departureTime.hour;
    int departureMinute = route.departureTime.minute;

    int totalMinutes =
        departureHour * 60 + departureMinute + route.duration.toInt() ~/ 60;

    int arrivalHour = (totalMinutes ~/ 60) % 24;
    int arrivalMinute = totalMinutes % 60;

    return formatTime(arrivalHour, arrivalMinute);
  }

  String getFreeSeats() {
    return route.freeSeats.toString();
  }

  String getImport() {
    return route.price.toString();
  }

  static const CameraPosition _kUPC = CameraPosition(
    bearing: 0.0,
    target: LatLng(41.38860749272642, 2.113867662148663),
    tilt: 0.0,
    zoom: 19.151926040649414,
  );

  Future<bool> canJoinRoute() async {
    bool canJoinRoute = false;
    try {
      canJoinRoute =
          await routeController.validateJoinToRoute(widget.routeOG.id);
    } on Exception catch (e) {
      _showErrorDialog(context, e.toString());
    }
    return canJoinRoute;
  }

  void _showReportCharger(BuildContext context, int chargerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reportar cargador',
              style: Theme.of(context).textTheme.labelLarge),
          content: Text('¿Seguro que quieres reportar este cargador?',
              style: Theme.of(context).textTheme.bodyMedium),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  color: Color(0xFFF44336),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                String response =
                    await routeController.reportCharger(chargerId);
                if (response == '') {
                  Navigator.of(context).pop();
                  _showChargerReported(context);
                } else {
                  _showErrorDialog(context, response);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translation(context).error),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              child: Text(translation(context).ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _joinRouteAction() async {
    bool bCanJoinRoute = await canJoinRoute();
    if (!bCanJoinRoute) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(route_id: widget.routeOG.id),
      ),
    );
  }

  void _fitMarkersToBounds() {
    if (_markers.isEmpty) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (Marker marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = min(minLat, lat);
      maxLat = max(maxLat, lat);
      minLng = min(minLng, lng);
      maxLng = max(maxLng, lng);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    const padding = 50.0;
    final cameraUpdate = CameraUpdate.newLatLngBounds(bounds, padding);

    _controller.future.then((controller) {
      controller.animateCamera(cameraUpdate);
    });
  }

  Future<MapRoute> getRoute(int routeId) async {
    return await routeController.getMapRoute(routeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 50,
            ),
            route.finalized ? _buildRouteFinalized() : Container(),
            const SizedBox(
              height: 15,
            ),
            _buildDiaSalida(),
            const SizedBox(
              height: 15,
            ),
            _buildCosaPau(context),
            _buildMap(),
            doneThisRoute ? SizedBox(height: 1) : _buildPrecioPorPasajero(),
            const SizedBox(height: 16),
            _buildUserInformation(),
            const SizedBox(height: 16),
            doneThisRoute ? SizedBox(height: 1) : _buildJoinRoute(),
          ],
        ),
      ),
      bottomNavigationBar: Bar(
        selectedIndex: doneThisRoute ? 1 : 0,
      ),
    );
  }

  Widget _buildPrecioPorPasajero() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: MediaQuery.of(context).size.height * 0.9,
        height: MediaQuery.of(context).size.height * 0.17,
        padding:
            const EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 10),
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
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text.rich(TextSpan(
                        text: translation(context).seatsLeft,
                        style: Theme.of(context).textTheme.bodySmall)),
                    Text.rich(TextSpan(
                        text: "${widget.routeOG.freeSeats}",
                        style: Theme.of(context).textTheme.displayLarge)),
                    Text.rich(TextSpan(
                        text: translation(context).seatsLeft2,
                        style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(TextSpan(
                        text:
                            "${translation(context).totalPrice} ${widget.seats} ${widget.seats == "1" ? translation(context).passenger : translation(context).passengers}",
                        style: Theme.of(context).textTheme.bodySmall)),
                    Text.rich(TextSpan(
                        text:
                            "${widget.routeOG.price * int.parse(widget.seats)} €",
                        style: Theme.of(context).textTheme.displayLarge))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCosaPau(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, right: 26, bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(widget.routeOG.departureTime),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(widget.routeOG.duration / 3600).floor()}h${((widget.routeOG.duration % 3600) / 60).round()}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      DateFormat('HH:mm').format(widget.routeOG.departureTime
                          .add(Duration(
                              seconds: (widget.routeOG.duration).toInt()))),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 30, height: 3),
                    Icon(Icons.circle_outlined,
                        size: 12, color: Theme.of(context).colorScheme.primary),
                    Container(
                        width: 4,
                        height: 40,
                        color: Theme.of(context).colorScheme.primary),
                    Icon(Icons.circle_outlined,
                        size: 12, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.routeOG.originAlias,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.displaySmall),
                      Row(
                        children: [
                          Stack(
                            children: [
                              Positioned(
                                  child: Icon(Icons.circle,
                                      size: 24,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary)),
                              Positioned(
                                  child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Icon(
                                          Icons.directions_walk_outlined,
                                          size: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .background))),
                            ],
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Flexible(
                            child: Text.rich(TextSpan(
                              text:
                                  "${translation(context).distanceFromDeparture} ${(widget.routeOG.distanceOrigin * 1000).toStringAsFixed(2)} m",
                              style: const TextStyle(
                                color: Color(0xFF686868),
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(widget.routeOG.destinationAlias,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.displaySmall),
                      Row(
                        children: [
                          Stack(
                            children: [
                              Positioned(
                                  child: Icon(Icons.circle,
                                      size: 24,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary)),
                              Positioned(
                                  child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Icon(
                                          Icons.directions_walk_outlined,
                                          size: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .background))),
                            ],
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Flexible(
                            child: Text.rich(TextSpan(
                              text:
                                  "${translation(context).distanceFromArrival} ${(widget.routeOG.distanceDestination * 1000).toStringAsFixed(2)} m",
                              style: const TextStyle(
                                color: Color(0xFF686868),
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaSalida() {
    return Row(
      children: [
        const SizedBox(
          width: 25,
        ),
        Text.rich(TextSpan(
            text: DateFormat('EEEE d \'of\' MMMM').format(route.departureTime),
            style: Theme.of(context).textTheme.displayLarge)),
      ],
    );
  }

  Widget _buildRouteFinalized() {
    return Row(
      children: [
        const SizedBox(
          width: 10,
        ),
        const Icon(
          Icons.lightbulb_outline,
          color: Colors.grey,
        ),
        Text.rich(TextSpan(
          text: translation(context).routeStarted,
          style: Theme.of(context).textTheme.bodySmall,
        )),
      ],
    );
  }

  Widget _buildUserInformation() {
    if (doneThisRoute && isDriver) {
      // Caso 1 y 4: El usuario pertenece a la ruta y es el conductor
      return Column(
        children: [
          ...passengers.map((passenger) => FutureBuilder(
                future: Future.wait([
                  userController.getUserProfileImage(passenger.id),
                  userController.getUserValoration(passenger.id),
                ]),
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text(translation(context).loadPassengerError);
                  }
                  String profileImage = snapshot.data![0] ?? '';

                  double? valoration = snapshot.data![1] as double?;
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  MyProfile(id: passenger.id)),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.height * 0.9,
                        padding: const EdgeInsets.all(10),
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
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.chevron_right),
                                CircleAvatar(
                                  backgroundImage: profileImage.isNotEmpty
                                      ? NetworkImage(profileImage)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      passenger.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: Colors.amber, size: 16),
                                        Text(
                                          valoration == null
                                              ? 'No tiene valoraciones'
                                              : valoration.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Color(0xFF686868),
                                            fontSize: 12,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Spacer(),
                                if (routeFinalized)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.star),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return RatingPopup(
                                                  receiver: passenger.id,
                                                  route: widget.routeOG.id);
                                            },
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.report),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (context) {
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                    bottom:
                                                        MediaQuery.of(context)
                                                            .viewInsets
                                                            .bottom),
                                                child: ReportUserPopup(
                                                    reportedUserId:
                                                        passenger.id),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )),
          if (passengers.isEmpty) Text(translation(context).noPassengers),
        ],
      );
    } else {
      // Caso 2 y 3: El usuario no es conductor
      return FutureBuilder(
        future: Future.wait([
          userController.getUserProfileImage(driver.id),
          userController.getUserValoration(driver.id),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Text(translation(context).loadDriverError);
          }
          String profileImage = snapshot.data![0] ?? '';
          double? valoration = snapshot.data![1] as double?;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MyProfile(id: driver.id)),
                );
              },
              child: Container(
                width: MediaQuery.of(context).size.height * 0.9,
                padding: const EdgeInsets.all(10),
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
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.chevron_right),
                        CircleAvatar(
                          backgroundImage: profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                Text(
                                    '${valoration == null ? 'No tiene valoraciones' : valoration.toStringAsFixed(1)}'),
                              ],
                            ),
                          ],
                        ),
                        Spacer(),
                        if (routeFinalized)
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.star),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return RatingPopup(
                                          receiver: driver.id,
                                          route: widget.routeOG.id);
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.report),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                            bottom: MediaQuery.of(context)
                                                .viewInsets
                                                .bottom),
                                        child: ReportUserPopup(
                                            reportedUserId: driver.id),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    driverPreferences.isEmpty
                        ? Container()
                        : Column(
                            children: driverPreferences.map((preference) {
                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  children: [
                                    ImageIcon(AssetImage(
                                        preferencesIcons[preference]!)),
                                    const SizedBox(width: 15.0),
                                    Flexible(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text.rich(TextSpan(
                                          text: preference,
                                          style: const TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Center _buildJoinRoute() {
    return Center(
      child: SizedBox(
        width: 300,
        child: ElevatedButton(
          onPressed: _joinRouteAction,
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(Colors.green[500]!),
          ),
          child: Text(
            translation(context).joinRoute,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  SizedBox _buildMap() {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _kUPC,
          markers: _markers,
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue,
              points: _polylineCoordinates,
            ),
          },
          onMapCreated: _onMapCreated,
        ),
      ),
    );
  }

  Future<Driver> getDriver() async {
    Driver aux = await userController.getDriverById(widget.routeOG.driverId);
    for (var i in aux.preferences.keys) {
      if (!driverPreferences.contains(preferencesNames[i]!) &&
          aux.preferences[i]!) {
        driverPreferences.add(preferencesNames[i]!);
      }
    }
    var valorations = await userController.getOtherUserComments(aux.id);
    if (valorations.isEmpty) {
      dirverValoration = 'NA';
    } else {
      double sum = 0;
      for (var i in valorations) {
        sum += i.rating;
      }
      dirverValoration = (sum / valorations.length).toStringAsFixed(1);
    }
    return aux;
  }

  void _showChargerReported(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Cargador reportado',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          content: const Text('El cargador ha sido reportado correctamente'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
