import 'package:flutter/material.dart';
import 'package:ppf_mobile_client/Controllers/GoogleAPIController.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/views/search_screen.dart';

class SuggestionScreen extends StatefulWidget {
  final int modify;
  final String departure;
  final String destination;
  final String tokenForSession;
  final DateTime date;
  final String seats;

  SuggestionScreen({
    Key? key,
    required this.tokenForSession,
    required this.departure,
    required this.destination,
    required this.modify,
    required this.date,
    required this.seats,
  }) : super(key: key);

  @override
  _SuggestionScreenState createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final TextEditingController _controller = TextEditingController();
  late FocusNode _focusNode; // Add this line
  late Future<List<dynamic>> _suggestions;
  String departure = '';
  String destination = '';

  @override
  void initState() {
    super.initState();
    _suggestions = _fetchSuggestions('');
    _controller.addListener(_onSearchTextChanged);
    departure = widget.departure;
    destination = widget.destination;
    if (widget.modify == 0) {
      _controller.text = departure;
    } else {
      _controller.text = destination;
    }
    _focusNode = FocusNode(); // Initialize focus node
    _focusNode.requestFocus(); // Request focus
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Dispose the focus node
    super.dispose();
  }

  void _onSearchTextChanged() {
    setState(() {
      _suggestions = _fetchSuggestions(_controller.text);
    });
  }

  Future<List<dynamic>> _fetchSuggestions(String value) async {
    if (widget.modify == 0) {
      return googleAPIController.makeSuggestionRemote(
        value,
        widget.tokenForSession,
      );
    }
    return googleAPIController.makeSuggestionRemote(
      value,
      widget.tokenForSession,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      body: Column(
        children: [
          const SizedBox(height: 40),
          Row(children: [
            const SizedBox(width: 20), // Extra space after the arrow
            Flexible(
              child: Container(
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
                  focusNode: _focusNode,
                  style: Theme.of(context).textTheme.bodyMedium,
                  controller: _controller,
                  decoration: InputDecoration(
                    prefixIcon: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 16),
                      onPressed: () {
                        if (widget.modify == 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return SearchScreen(
                                departure: _controller.text,
                                destination: destination,
                                date: widget.date,
                                freeSpaces: widget.seats,
                              );
                            }),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return SearchScreen(
                                departure: departure,
                                destination: _controller.text,
                                date: widget.date,
                                freeSpaces: widget.seats,
                              );
                            }),
                          );
                        }
                      },
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                          size: 18),
                      onPressed: () {
                        _controller.clear();
                      },
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.background,
                    hintText: translation(context).buscarLugar,
                    hintStyle: Theme.of(context).textTheme.bodyMedium,
                    contentPadding: const EdgeInsets.only(
                        left: 14.0, bottom: 8.0, top: 8.0),
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
                ),
              ),
            ),
            const SizedBox(width: 20),
          ]),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _suggestions,
              builder: (context, snapshot) {
                List<String> suggestionList =
                    (snapshot.data ?? []).map<String>((dynamic item) {
                  return item['description'].toString();
                }).toList();
                return ListView.builder(
                  itemCount: suggestionList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        onTap: () async {
                          if (widget.modify == 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return SearchScreen(
                                  departure:
                                      translation(context).posicionActual,
                                  destination: destination,
                                  date: widget.date,
                                  freeSpaces: widget.seats,
                                );
                              }),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return SearchScreen(
                                  departure: departure,
                                  destination:
                                      translation(context).posicionActual,
                                  date: widget.date,
                                  freeSpaces: widget.seats,
                                );
                              }),
                            );
                          }
                        },
                        title: Text(translation(context).posicionActual,
                            style: Theme.of(context).textTheme.labelLarge),
                      );
                    } else {
                      return ListTile(
                        title: Text(suggestionList[index - 1]),
                        onTap: () {
                          if (widget.modify == 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return SearchScreen(
                                  departure: suggestionList[index - 1],
                                  destination: destination,
                                  date: widget.date,
                                  freeSpaces: widget.seats,
                                );
                              }),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return SearchScreen(
                                  departure: departure,
                                  destination: suggestionList[index - 1],
                                  date: widget.date,
                                  freeSpaces: widget.seats,
                                );
                              }),
                            );
                          }
                        },
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
