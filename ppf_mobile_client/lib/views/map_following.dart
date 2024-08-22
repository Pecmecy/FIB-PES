import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:ppf_mobile_client/Controllers/RouteController.dart';
import 'package:ppf_mobile_client/Models/Route.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/config.dart';
import 'package:ppf_mobile_client/views/search_screen.dart';

class MapFollowing extends StatefulWidget {
  final double initialAutonomy; // Initial autonomy in kilometers
  final int routeId; // Route ID to fetch from backend

  const MapFollowing({super.key, this.initialAutonomy = 0, this.routeId = 0});

  @override
  State<MapFollowing> createState() => _MapFollowingState();
}

class _MapFollowingState extends State<MapFollowing> {
  late GoogleMapController _mapController;
  LatLng _currentPosition = const LatLng(0, 0);
  LatLng?
      _previousPosition; // To store the previous position for bearing calculation
  late LatLng _destination; // Destination will be set dynamically
  final List<LatLng> _polylineCoordinates = [];
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  bool _hasArrived = false;
// Remaining autonomy in kilometers

  late double bearing = 0;

  late BitmapDescriptor _carIcon; // Variable to store the custom marker icon
  late MapRoute route;

  @override
  void initState() {
    super.initState();
    _loadCarIcon();
    _getRouteDetails(widget.routeId);
  }

  Future<void> _loadCarIcon() async {
    // Load image from assets
    final ByteData data = await rootBundle.load('assets/maps_car_icon.png');
    final Uint8List bytes = data.buffer.asUint8List();

    // Decode the image
    img.Image originalImage = img.decodeImage(bytes)!;

    // Resize the image
    img.Image resizedImage =
        img.copyResize(originalImage, width: 192, height: 192);

    // Convert back to bytes
    final resizedBytes = Uint8List.fromList(img.encodePng(resizedImage));

    // Convert to BitmapDescriptor
    _carIcon = BitmapDescriptor.fromBytes(resizedBytes);
  }

  Future<MapRoute> getRoute(int routeId) async {
    return await routeController.getMapRoute(routeId);
  }

  Future<void> _getRouteDetails(int routeId) async {
    try {
      route = await getRoute(routeId);
      _destination = LatLng(route.destinationLat, route.destinationLon);
      await _getCurrentLocation();
    } catch (error) {
      // Fallback to default location if API call fails
      _destination =
          const LatLng(41.38778735503038, 2.169668044368149); // Pl. Catalunya
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _previousPosition = _currentPosition; // Initialize previous position
      _updateMarkers();
      _mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 18,
          bearing: bearing, // Rotate the map based on the bearing
          tilt: 0,
        ),
      ));
    });

    await _getPolyline();
    Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    )).listen((Position position) {
      if (_hasArrived) return; // Stop updating if arrived

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        if (_previousPosition != null) {
// Update autonomy (km)
        }
        _updateMarkers();
      });

      // Calculate bearing (direction) if we have a previous position
      if (_previousPosition != null) {
        bearing = Geolocator.bearingBetween(
          _previousPosition!.latitude,
          _previousPosition!.longitude,
          _currentPosition.latitude,
          _currentPosition.longitude,
        );
      }

      _mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 18,
          bearing: bearing, // Rotate the map based on the bearing
          tilt: 0,
        ),
      ));

      _previousPosition = _currentPosition; // Update previous position

      _checkDeviation();
      _checkArrival();
    });
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: _currentPosition,
          icon: _carIcon, // Use the custom car icon
          anchor: const Offset(0.5, 0.5), // Center the icon
        ),
      );
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination,
        ),
      );

      int chargerCount = 0;
      for (var charger in chargers) {
        _markers.add(
          Marker(
            markerId: MarkerId('charger$chargerCount'),
            position: charger,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen), // Use green icon
            infoWindow: InfoWindow(
              title: '${translation(context).charger} ${chargerCount + 1}',
              snippet: '${charger.latitude}, ${charger.longitude}',
            ),
            onTap: () {
              _mapController.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: charger,
                  zoom: 18,
                ),
              ));
            },
          ),
        );
        chargerCount++;
      }
    });
  }

  Future<void> _getPolyline() async {
    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> polylineCoordinates = [];

    // Generate polyline
    List<PointLatLng> points = [];
    try {
      Map<String, dynamic> result = await routeController.getPolyline(
          _currentPosition, LatLng(route.destinationLat, route.destinationLon));

      if (result.containsKey('polyline') && result['polyline'] != null) {
        points = (result['polyline'] as Polyline)
            .points
            .map((point) => PointLatLng(point.latitude, point.longitude))
            .toList();
      }

      if (result.containsKey('chargers') && result['chargers'] != null) {
        chargers = result['chargers'] as List<LatLng>;
      } else {
        chargers = [];
      }
    } catch (e) {
      // Calculate initial route
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        GOOGLE_MAPS_API_KEY,
        PointLatLng(_currentPosition.latitude, _currentPosition.longitude),
        PointLatLng(_destination.latitude, _destination.longitude),
        travelMode: TravelMode.driving,
      );
      points = result.points;
      if (kDebugMode) {
        print('Error getting polyline: $e');
      }
    }

    if (points.isNotEmpty) {
      for (var point in points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    setState(() {
      _polylineCoordinates.clear();
      _polylineCoordinates.addAll(polylineCoordinates);
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('polyline'),
          color: Colors.blue,
          points: _polylineCoordinates,
          width: 5,
        ),
      );
      _updateMarkers(); // Update markers to include new chargers
    });
  }

  List<LatLng> chargers = [];

  void _checkDeviation() {
    if (_polylineCoordinates.isEmpty) return;

    double minDistance = double.infinity;
    for (LatLng point in _polylineCoordinates) {
      double distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }

      if (minDistance < 10) {
        break;
      }
    }

    // Threshold distance to consider deviation (e.g., 10 meters)
    if (minDistance > 10) {
      _getPolyline();
    }
  }

  Future<void> _checkArrival() async {
    double distanceToDestination = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _destination.latitude,
      _destination.longitude,
    );

    // Threshold distance to show arrival message (e.g., 30 meters)
    if (distanceToDestination <= 30 && !_hasArrived) {
      _hasArrived = true; // Mark arrival to stop further updates
      try {
        await routeController.finishRoute(widget.routeId);
      } on Exception catch (e) {
        debugPrint(e.toString());
      }
      _showArrivalDialog();
    }
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translation(context).arrivedTitle),
          content: Text(translation(context).arrivedMessage),
          actions: <Widget>[
            TextButton(
              child: Text(translation(context).ok),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        title: const SizedBox.shrink(),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 15.0,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        myLocationEnabled: false, // Disable the blue dot
        myLocationButtonEnabled: false, // Disable the location button
        markers: _markers,
        polylines: _polylines,
      ),
    );
  }
}
