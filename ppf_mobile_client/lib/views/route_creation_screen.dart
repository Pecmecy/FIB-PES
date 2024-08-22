import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ppf_mobile_client/Controllers/GoogleAPIController.dart';
import 'package:ppf_mobile_client/Controllers/RouteController.dart';
import 'package:ppf_mobile_client/Models/Route.dart';
import 'package:ppf_mobile_client/Models/RouteData.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/global_widgets/NavigationBar.dart';
import 'package:ppf_mobile_client/views/search_screen.dart';
import 'package:uuid/uuid.dart';

class RouteCreationScreen extends StatefulWidget {
  const RouteCreationScreen({super.key});

  @override
  State<RouteCreationScreen> createState() => _RouteCreationScreenState();
}

class _RouteCreationScreenState extends State<RouteCreationScreen> {
  late MapRoute route = MapRoute.empty();

  String tokenForSession = '';
  LatLng currentUserPosition = const LatLng(0.0, 0.0);

  Map<PolylineId, Polyline> polylines = {};

  String selectedDepartureAddress = '';
  LatLng selectedDepartureLatLng = const LatLng(0.0, 0.0);

  String selectedDestinationAddress = '';
  LatLng selectedDestinationLatLng = const LatLng(0.0, 0.0);

  var uuid = const Uuid();

  List<dynamic> listForDepartures = [];
  List<dynamic> listForDestinations = [];

  DateTime? _selectedDate;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _freeSpacesController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  final Set<Marker> _markers = {};
  bool valid = false;
  bool departureIsUserLocation = true;

  void _onMapCreated(GoogleMapController controller) async {
    setState(() {
      _liveLocation();
    });
    await getCurrentLocation();
    _cameraToPosition(currentUserPosition);
    _mapController.complete(controller);
    _markers.add(Marker(
        markerId: const MarkerId('currentPosition'),
        position: currentUserPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _liveLocation();
    getCurrentLatLng();
    _departureController.addListener(() {
      onModifyDeparture();
    });
    _destinationController.addListener(() {
      onModifyDestination();
    });
    makeDepartureSuggestion(_departureController.text);
    makeDestinationSuggestion(_destinationController.text);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _closeSuggestionLists();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Row(children: [
                  const SizedBox(width: 12),
                  const Column(
                    children: [
                      SizedBox(height: 12.0),
                      Icon(Icons.circle_outlined, size: 20),
                      SizedBox(width: 10),
                      Icon(Icons.more_vert, size: 30)
                    ],
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                      child: _buildTextField(
                          _departureController,
                          translation(context).salida,
                          const Icon(Icons.search))),
                  const SizedBox(width: 16),
                ]),
                _buildDepartureSuggestionList(),
                Row(children: [
                  const SizedBox(width: 12),
                  const Column(
                    children: [
                      SizedBox(height: 4.0),
                      Icon(Icons.location_on_outlined, size: 30),
                      SizedBox(height: 16),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                      child: _buildTextField(
                          _destinationController,
                          translation(context).destino,
                          const Icon(Icons.search))),
                  const SizedBox(width: 16),
                ]),
                _buildDestinationSuggestionList(),
                const SizedBox(height: 4.0),
                const Divider(),
                const SizedBox(height: 4.0),
                Row(children: [
                  const SizedBox(width: 16),
                  Flexible(child: _buildFieldSelectors()),
                  const SizedBox(width: 16),
                ]),
                const SizedBox(height: 20),
                _buildMap(),
                const SizedBox(height: 16.0),
                _buildCreateRouteButton(),
                const SizedBox(height: 16.0),
              ],
            )),
        bottomNavigationBar: const Bar(selectedIndex: 2),
      ),
    );
  }

  Widget _buildMap() {
    return SizedBox(
      height: 400,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition:
            CameraPosition(target: currentUserPosition, zoom: 14),
        markers: _markers,
        polylines: Set<Polyline>.of(polylines.values),
        onMapCreated: _onMapCreated,
      ),
    );
  }

  Widget _buildDepartureSuggestionList() {
    return Visibility(
        visible: _departureController.text.isNotEmpty &&
            listForDepartures.isNotEmpty,
        child: SizedBox(
          height: 300,
          child: ListView.builder(
              itemCount: listForDepartures.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    onTap: () async {
                      List<Placemark> placemarks =
                          await placemarkFromCoordinates(
                              currentUserPosition.latitude,
                              currentUserPosition.longitude);
                      Placemark currentPlacemark = placemarks.first;
                      setState(() {
                        selectedDepartureAddress =
                            "${currentPlacemark.name ?? ""}, ${currentPlacemark.street ?? ""}, ${currentPlacemark.subLocality ?? ""}, ${currentPlacemark.locality ?? ""}, ${currentPlacemark.administrativeArea ?? ""}, ${currentPlacemark.country ?? ""}";
                        _departureController.text = selectedDepartureAddress;
                        listForDepartures = [];
                      });
                      try {
                        selectedDepartureLatLng = LatLng(
                            currentUserPosition.latitude,
                            currentUserPosition.longitude);
                        departureSelected();
                        suggestionSelected();
                      } catch (e) {
                        _showError(translation(context).errorConexionServidor);
                      }
                    },
                    title: Text(translation(context).posicionActual,
                        style: Theme.of(context).textTheme.labelLarge),
                  );
                } else {
                  return ListTile(
                    onTap: () async {
                      setState(() {
                        selectedDepartureAddress =
                            listForDepartures[index - 1]['description'];
                        _departureController.text = selectedDepartureAddress;
                        listForDepartures =
                            []; // Cerrar la lista de sugerencias
                      });
                      try {
                        List<Location> locations =
                            await locationFromAddress(selectedDepartureAddress);
                        selectedDepartureLatLng = LatLng(
                            locations.last.latitude, locations.last.longitude);
                        departureSelected();
                        suggestionSelected();
                      } catch (e) {
                        _showError(translation(context).errorDireccionInvalida);
                      }
                    },
                    title: Text(listForDepartures[index - 1]['description']),
                  );
                }
              }),
        ));
  }

  Widget _buildDestinationSuggestionList() {
    return Visibility(
        visible: _destinationController.text.isNotEmpty &&
            listForDestinations.isNotEmpty,
        child: SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: listForDestinations.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  onTap: () async {
                    List<Placemark> placemarks = await placemarkFromCoordinates(
                        currentUserPosition.latitude,
                        currentUserPosition.longitude);
                    Placemark currentPlacemark = placemarks.first;
                    setState(() {
                      selectedDestinationAddress =
                          "${currentPlacemark.name ?? ""}, ${currentPlacemark.street ?? ""}, ${currentPlacemark.subLocality ?? ""}, ${currentPlacemark.locality ?? ""}, ${currentPlacemark.administrativeArea ?? ""}, ${currentPlacemark.country ?? ""}";
                      _destinationController.text = selectedDestinationAddress;
                      listForDestinations = [];
                    });
                    try {
                      selectedDestinationLatLng = LatLng(
                          currentUserPosition.latitude,
                          currentUserPosition.longitude);
                      destinationSelected();
                      suggestionSelected();
                    } catch (e) {
                      _showError(translation(context).errorConexionServidor);
                    }
                  },
                  title: Text(translation(context).posicionActual,
                      style: Theme.of(context).textTheme.labelLarge),
                );
              } else {
                return ListTile(
                  onTap: () async {
                    setState(() {
                      selectedDestinationAddress =
                          listForDestinations[index - 1]['description'];
                      _destinationController.text = selectedDestinationAddress;
                      listForDestinations = [];
                    });
                    try {
                      List<Location> locations =
                          await locationFromAddress(selectedDestinationAddress);
                      selectedDestinationLatLng = LatLng(
                          locations.last.latitude, locations.last.longitude);
                      destinationSelected();
                      suggestionSelected();
                    } catch (e) {
                      _showError(translation(context).errorDireccionInvalida);
                    }
                  },
                  title: Text(listForDestinations[index - 1]['description']),
                );
              }
            },
          ),
        ));
  }

  Widget _buildTextField(
      TextEditingController contr, String? hint, Icon sufix) {
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
          onTap: () {
            setState(() {
              listForDepartures = [];
              listForDestinations = [];
            });
          },
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: Icon(Icons.close,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  size: 18),
              onPressed: () {
                contr.clear();
              },
            ),
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: TextStyle(
                fontSize: 18.0,
                color: Colors.grey[500],
                fontWeight: FontWeight.normal),
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

  Widget _buildNumberField(
      TextEditingController contr, String? hint, Icon sufix, bool isDouble) {
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
          keyboardType: TextInputType.number,
          onTap: () {
            setState(() {
              listForDepartures = [];
              listForDestinations = [];
            });
          },
          inputFormatters: isDouble
              ? <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 .]'))
                ]
              : <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 18.0),
          decoration: InputDecoration(
            suffixIcon: sufix,
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: TextStyle(
                fontSize: 18.0,
                color: Colors.grey[500],
                fontWeight: FontWeight.normal),
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

  Future<void> _cameraToPosition(LatLng position) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 14)));
  }

  Widget _buildCreateRouteButton() {
    return Center(
      child: SizedBox(
        height: 50,
        width: 300,
        child: ElevatedButton(
          onPressed: createRouteAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(
            translation(context).crearRuta,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }

  void _fitRouteBounds(List<LatLng> coordinates) {
    double minLat = coordinates[0].latitude;
    double maxLat = coordinates[0].latitude;
    double minLong = coordinates[0].longitude;
    double maxLong = coordinates[0].longitude;

    for (LatLng coord in coordinates) {
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.longitude > maxLong) maxLong = coord.longitude;
      if (coord.longitude < minLong) minLong = coord.longitude;
    }

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLong),
      northeast: LatLng(maxLat, maxLong),
    );

    _mapController.future.then((controller) {
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    });
  }

  void _liveLocation() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        currentUserPosition = positionToLatLng(position);
      });
    });
  }

  Future<void> getCurrentLatLng() async {
    Position position = await getCurrentLocation();
    currentUserPosition = positionToLatLng(position);
    return;
  }

  LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError(translation(context).servicioUbicacionDeshabilitado);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError(translation(context).permisosUbicacionDenegados);
      }
      if (permission == LocationPermission.deniedForever) {
        _showError(
            translation(context).permisosUbicacionDenegadosPermanentemente);
      }
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    return position;
  }

  Future<void> createRouteAction() async {
    //Check for nulls
    String freeSpaces = _freeSpacesController.text;
    String price = _priceController.text;
    if (selectedDepartureAddress.isEmpty ||
        selectedDepartureLatLng.latitude == 0.0 ||
        selectedDepartureLatLng.longitude == 0.0 ||
        selectedDestinationAddress.isEmpty ||
        selectedDestinationLatLng.latitude == 0.0 ||
        selectedDestinationLatLng.longitude == 0.0 ||
        _selectedDate == null ||
        freeSpaces.isEmpty ||
        price.isEmpty) {
      _showError(translation(context).relleneTodosLosCampos);
    } else if (valid == false) {
      _showError(translation(context).errorAutonomiaVehiculo);
    } else {
      var response = await routeController.registerRoute(
          selectedDepartureAddress,
          selectedDepartureLatLng.latitude,
          selectedDepartureLatLng.longitude,
          selectedDestinationAddress,
          selectedDestinationLatLng.latitude,
          selectedDestinationLatLng.longitude,
          _selectedDate,
          freeSpaces,
          price);
      if (response == '') {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SearchScreen()));
      } else {
        _showError(translation(context).errorCrearRuta);
      }
    }
  }

  void makeDepartureSuggestion(String input) async {
    try {
      var suggestions = await googleAPIController.makeSuggestionRemote(
          input, tokenForSession);
      setState(() {
        listForDepartures = suggestions;
      });
    } catch (e) {
      _showError(translation(context).errorConexionServidor);
    }
  }

  void makeDestinationSuggestion(String input) async {
    try {
      var suggestions = await googleAPIController.makeSuggestionRemote(
          input, tokenForSession);
      setState(() {
        listForDestinations = suggestions;
      });
    } catch (e) {
      _showError(translation(context).errorConexionServidor);
    }
  }

  bool markersContain(String id) {
    for (Marker marker in _markers) {
      if (marker.markerId.value == id) {
        return true;
      }
    }
    return false;
  }

  void destinationSelected() {
    bool markerFound = false;
    for (Marker marker in _markers) {
      if (marker.markerId.value == 'destination') {
        markerFound = true;
        _markers.remove(marker); // Remove existing marker
        _markers.add(
          // Add updated marker with new position
          Marker(
            markerId: const MarkerId('destination'),
            position: selectedDestinationLatLng,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
        setState(() {});
        break;
      }
    }
    if (!markerFound) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: selectedDestinationLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      setState(() {});
    }
  }

  void departureSelected() {
    departureIsUserLocation = false;
    bool markerFound = false;
    for (Marker marker in _markers) {
      if (marker.markerId.value == 'departure') {
        markerFound = true;
        _markers.remove(marker); // Remove existing marker
        _markers.add(
          // Add updated marker with new position
          Marker(
            markerId: const MarkerId('departure'),
            position: selectedDepartureLatLng,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
        setState(() {});
        break;
      }
    }
    if (!markerFound) {
      _markers.add(
        Marker(
          markerId: const MarkerId('departure'),
          position: selectedDepartureLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      setState(() {});
    }
  }

  void suggestionSelected() {
    //Both suggestions selected
    if (_destinationController.text.contains('France')) {
        _destinationController.clear();
        _showError("Siento mucho que tengas que pisar a Francia, no vamos a ser participes de eso");
        return;
      }
     if (_departureController.text.contains('France')) {
        _departureController.clear();
        _showError(
            "Siento mucho que tengas que pisar a Francia, no vamos a ser participes de eso");
        return;
      }
    setState(() {});
    if (selectedDepartureLatLng.latitude != 0 &&
        selectedDepartureLatLng.latitude != 0 &&
        selectedDestinationLatLng.latitude != 0 &&
        selectedDestinationLatLng.longitude != 0) {
      getPolylinePoints().then((coordinates) => {
            generatePolyLineFromPoints(coordinates),
            _fitRouteBounds(coordinates),
          });
    }
    //Only one suggestion selected
    else if ((selectedDepartureLatLng.latitude != 0 &&
            selectedDepartureLatLng.latitude != 0) ||
        (selectedDestinationLatLng.latitude != 0 &&
            selectedDestinationLatLng.longitude != 0)) {
      //Selected departure
      if (selectedDepartureLatLng.latitude != 0 &&
          selectedDepartureLatLng.latitude != 0) {
        _cameraToPosition(selectedDepartureLatLng);
      }
      //Selected destination
      else if (selectedDestinationLatLng.latitude != 0 &&
          selectedDestinationLatLng.longitude != 0) {
        _cameraToPosition(selectedDestinationLatLng);
      }
    }
  }

  void onSuggestionDepartureSelected(String suggestion) {
    // Cierra la lista de sugerencias
    setState(() {
      listForDepartures = [];
    });
  }

  void onSuggestionDestinationSelected(String suggestion) {
    // Cierra la lista de sugerencias
    setState(() {
      listForDestinations = [];
    });
  }

  void onModifyDeparture() {
    // Verifica si el texto actual es igual al valor seleccionado anteriormente
    if (_departureController.text != selectedDepartureAddress) {
      // Si son diferentes, actualiza el valor seleccionado y haz una nueva solicitud de sugerencias
      setState(() {
        selectedDepartureAddress = _departureController.text;
      });
      if (tokenForSession == '') {
        setState(() {
          tokenForSession = uuid.v4();
        });
      }
      makeDepartureSuggestion(selectedDepartureAddress);
    }
  }

  void onModifyDestination() {
    // Verifica si el texto actual es igual al valor seleccionado anteriormente
    if (_destinationController.text != selectedDestinationAddress) {
      // Si son diferentes, actualiza el valor seleccionado y haz una nueva solicitud de sugerencias
      setState(() {
        selectedDestinationAddress = _destinationController.text;
      });
      if (tokenForSession == '') {
        setState(() {
          tokenForSession = uuid.v4();
        });
      }
      makeDestinationSuggestion(selectedDestinationAddress);
    }
  }

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
                fillColor: Colors.white,
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
                  ? RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          const WidgetSpan(
                            child: Icon(Icons.calendar_month, size: 18),
                          ),
                          TextSpan(
                            text: translation(context).salida,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          const WidgetSpan(
                            child: Icon(Icons.calendar_month, size: 18),
                          ),
                          TextSpan(
                            text:
                                '${_selectedDate?.day}/${_selectedDate?.month}/${_selectedDate?.year}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ))),
    );
  }

  _selectDate(BuildContext context) {
    setState(() {
      listForDepartures = [];
      listForDestinations = [];
    });
    if (_selectedDate != null) {
      return DatePicker.showDatePicker(
        context,
        dateFormat: 'dd MMMM yyyy HH:mm',
        initialDateTime: _selectedDate!,
        minDateTime: DateTime.now(),
        maxDateTime: DateTime(3000),
        onMonthChangeStartWithFirstDate: true,
        onConfirm: (dateTime, List<int> index) {
          setState(() {
            _selectedDate = dateTime;
          });
        },
      );
    } else {
      return DatePicker.showDatePicker(
        context,
        dateFormat: 'dd MMMM yyyy HH:mm',
        initialDateTime: DateTime.now(),
        minDateTime: DateTime.now(),
        maxDateTime: DateTime(3000),
        onMonthChangeStartWithFirstDate: true,
        onConfirm: (dateTime, List<int> index) {
          setState(() {
            _selectedDate = dateTime;
          });
        },
      );
    }
  }

  Widget _buildFieldSelectors() {
    return Row(
      children: [
        Expanded(child: _buildDateSelector()),
        const SizedBox(width: 16),
        Expanded(
            child: _buildNumberField(
                _priceController,
                translation(context).precio,
                const Icon(Icons.euro, size: 16),
                true)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildNumberField(
                _freeSpacesController,
                translation(context).plazasLibres,
                const Icon(Icons.person, size: 18),
                false))
      ],
    );
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
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _closeSuggestionLists() {
    setState(() {
      listForDepartures = [];
      listForDestinations = [];
    });
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    try {
      RouteData result = await routeController.getRouteBetweenCoordinates(
        selectedDepartureLatLng.latitude,
        selectedDepartureLatLng.longitude,
        selectedDestinationLatLng.latitude,
        selectedDestinationLatLng.longitude,
      );

      if (result.polyline.isNotEmpty) {
        debugPrint(result.polyline.toString());
        polylineCoordinates = result.polyline
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        valid = true;
      } else {
        valid = false;
        debugPrint(
          translation(context).errorRutaSeleccionada,
        );
      }

      if (result.chargers.isNotEmpty) {
        debugPrint(result.chargers.toString());
        _markers.removeWhere((marker) {
          String markerIdValue = marker.markerId.value;
          return int.tryParse(markerIdValue) != null;
        });
        for (int i = 0; i < result.chargers.length; i++) {
          _markers.add(
            Marker(
              markerId: MarkerId(i.toString()),
              position: LatLng(result.chargers[i].lat, result.chargers[i].lon),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception: ${e.toString()}');
      if (departureIsUserLocation) {
        _cameraToPosition(selectedDestinationLatLng);
      } else {
        debugPrint(
          translation(context).errorRutaSeleccionada,
        );
      }
    }

    return polylineCoordinates;
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = const PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );
    setState(() {
      polylines[id] = polyline;
    });
  }
}
