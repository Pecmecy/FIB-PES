import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/global_widgets/NavigationBar.dart';
import 'package:ppf_mobile_client/views/search_results_screen.dart';
import 'package:ppf_mobile_client/views/suggestion_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? departure;
  final String? destination;
  final DateTime? date;
  final String? freeSpaces;

  const SearchScreen(
      {super.key,
      this.departure,
      this.destination,
      this.date,
      this.freeSpaces});

  @override
  // ignore: library_private_types_in_public_api
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String tokenForSession = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _freeSpacesController = TextEditingController();
  String _departure = '';
  String _destination = '';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _departure = widget.departure ?? '';
    _destination = widget.destination ?? '';
    _selectedDate = widget.date ?? DateTime.now();
    _freeSpacesController.text = widget.freeSpaces ?? '1';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Transform.rotate(
              angle: 0,
              child: Container(
                width: screenWidth,
                height: screenHeight / 2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF), // White color at the top
                      Color(0xFFCADEBC), // Green color at the bottom
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(
                0, -0.75), // Center horizontally and vertically shift up
            child: Image.asset('assets/logo.png', width: 150, height: 150),
          ),
          Positioned(
            top: -10,
            left: -10,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 120,
                height: 120,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: 40,
            child: Transform.rotate(
              angle: -0.65,
              child: Container(
                width: 150,
                height: 150,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: screenHeight - 110,
            left: screenWidth - 120,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: 240,
                height: 240,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: screenHeight - 120,
            left: -105,
            child: Transform.rotate(
              angle: 0.20,
              child: Container(
                width: 120,
                height: 120,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: screenHeight - 170,
            left: -40,
            child: Transform.rotate(
              angle: 0.80,
              child: Container(
                width: 80,
                height: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: screenWidth - 40,
            child: Transform.rotate(
              angle: -0.80,
              child: Container(
                width: 80,
                height: 80,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.5,
            left: 0,
            child: Transform.rotate(
              angle: 0,
              child: SizedBox(
                width: screenWidth,
                height: screenHeight * 0.5,
                child: Image.asset('assets/background1.jpg', fit: BoxFit.cover),
              ),
            ),
          ),
          Positioned(
            top: screenHeight / 2 - 150,
            left: screenWidth * 0.075,
            child: Container(
              width: screenWidth * 0.85,
              height: 285,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow,
                    blurRadius: 10.0,
                  ),
                ],
                borderRadius: BorderRadius.circular(20.0),
                color: Theme.of(context).colorScheme.background,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20, width: 0),
                  SizedBox(
                      width: screenWidth * 0.85,
                      child: Padding(
                          padding:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: _buildTextField(
                              _departure,
                              const Icon(Icons.circle_outlined),
                              0,
                              translation(context).de))),
                  const Divider(indent: 40, endIndent: 40),
                  Flexible(
                      child: Padding(
                          padding:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: _buildTextField(
                              _destination,
                              const Icon(Icons.circle_outlined),
                              1,
                              translation(context).a))),
                  const Divider(indent: 40, endIndent: 40),
                  Flexible(
                      child: Padding(
                          padding:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: _buildDateSelector())),
                  const Divider(indent: 40, endIndent: 40),
                  Flexible(
                      child: Padding(
                          padding:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: _buildNumberField(
                              _freeSpacesController,
                              translation(context).plazasLibres,
                              const Icon(Icons.person_outline, size: 18),
                              false))),
                  SizedBox(
                    width: double.infinity, // To occupy the whole width
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16.0),
                              bottomRight: Radius.circular(16.0)),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () async {
                        bool departureLatLon = false;
                        bool destinationLatLon = false;
                        double departureLat = 0;
                        double departureLon = 0;
                        double destinationLat = 0;
                        double destinationLon = 0;
                        if (_departure == translation(context).posicionActual) {
                          try {
                            Position position = await getCurrentLocation();
                            departureLat = position.latitude;
                            departureLon = position.longitude;
                            departureLatLon = true;
                          } catch (e) {
                            departureLatLon = false;
                            _showError(translation(context).ubicacionError);
                          }
                        }
                        if (_destination ==
                            translation(context).posicionActual) {
                          try {
                            Position position = await getCurrentLocation();
                            destinationLat = position.latitude;
                            destinationLon = position.longitude;
                            destinationLatLon = true;
                          } catch (e) {
                            destinationLatLon = false;
                            _showError(translation(context).ubicacionError);
                          }
                        }
                        if (_departure == translation(context).de ||
                            _destination == translation(context).a) {
                          _showError(translation(context).camposError);
                          return;
                        }
                        if (departureLatLon == false) {
                          try {
                            List<Location> locations =
                                await locationFromAddress(_departure,
                                    localeIdentifier: 'es_ES');

                            departureLatLon = true;

                            departureLat = locations.last.latitude;
                            departureLon = locations.last.longitude;
                          } catch (e) {
                            departureLatLon = false;
                          }
                        }
                        if (destinationLatLon == false) {
                          try {
                            List<Location> locations =
                                await locationFromAddress(_destination,
                                    localeIdentifier: 'es_ES');

                            destinationLatLon = true;

                            destinationLat = locations.last.latitude;
                            destinationLon = locations.last.longitude;
                          } catch (e) {
                            departureLatLon = false;
                          }
                          if (!departureLatLon || !destinationLatLon) {
                            _showError(translation(context).direccionError);
                            return;
                          }
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SearchResults(
                                    departure: _departure,
                                    destination: _destination,
                                    date: _selectedDate,
                                    freeSpaces: _freeSpacesController.text,
                                    departureLat: departureLat,
                                    departureLon: departureLon,
                                    destinationLat: destinationLat,
                                    destinationLon: destinationLon,
                                  )),
                        );
                      },
                      child: Text(
                        translation(context).buscar,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const Bar(selectedIndex: 0),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
          decoration: InputDecoration(
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
            filled: true,
            fillColor: Theme.of(context).colorScheme.background,
            contentPadding:
                const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
          ),
          child: (_selectedDate.day == DateTime.now().day &&
                  _selectedDate.month == DateTime.now().month &&
                  _selectedDate.year == DateTime.now().year)
              ? RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      const WidgetSpan(
                        child: Icon(Icons.calendar_month_outlined, size: 18),
                      ),
                      TextSpan(
                        text: translation(context).hoy,
                        style: Theme.of(context).textTheme.bodyMedium,
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
                            '  ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )),
    );
  }

  Widget _buildNumberField(
      TextEditingController contr, String? hint, Icon prefix, bool isDouble) {
    return TextField(
      controller: contr,
      autofocus: false,
      keyboardType: TextInputType.number,
      inputFormatters: isDouble
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 .]'))
            ]
          : <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
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
        prefixIcon: prefix,
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyMedium,
        contentPadding:
            const EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      helpText: translation(context).fechaSalida,
      cancelText: translation(context).cancelar,
      confirmText: translation(context).seleccionar,
      errorFormatText: translation(context).errorFormatoFecha,
      errorInvalidText: translation(context).errorFechaInvalida,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildTextField(
      String? message, Icon prefix, int modify, String defaultMessage) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SuggestionScreen(
            modify: modify,
            departure: _departure,
            destination: _destination,
            tokenForSession: tokenForSession,
            date: _selectedDate,
            seats: _freeSpacesController.text,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.background,
          ),
        ),
        child: Row(
          children: [
            prefix,
            const SizedBox(width: 8.0),
            Expanded(
              // Added to constrain width
              child: Text(
                message != null && message != '' ? message : defaultMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis, // Ensure text does not overflow
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError(translation(context).servicioUbicacionError);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError(translation(context).permisoUbicacionDenegado);
      }
      if (permission == LocationPermission.deniedForever) {
        _showError(translation(context).permisoUbicacionDenegadoPermanente);
      }
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    return position;
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
