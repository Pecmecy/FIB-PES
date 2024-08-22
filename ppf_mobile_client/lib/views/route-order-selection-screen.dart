import 'package:flutter/material.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';
import 'package:ppf_mobile_client/views/search_results_screen.dart';

class OrderSelection extends StatefulWidget {
  final String departure;
  final String destination;
  final DateTime date;
  final String freeSpaces;
  final double departureLat;
  final double departureLon;
  final double destinationLat;
  final double destinationLon;
  final String? order;

  const OrderSelection({
    super.key,
    required this.departure,
    required this.destination,
    required this.date,
    required this.freeSpaces,
    required this.departureLat,
    required this.departureLon,
    required this.destinationLat,
    required this.destinationLon,
    this.order,
  });

  @override
  State<OrderSelection> createState() => _OrderSelectionState();
}

enum OrderOption { time, price, departureDistance, destinationDistance }

class _OrderSelectionState extends State<OrderSelection> {
  OrderOption? _selectedOption = OrderOption.time;

  void _onButtonPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResults(
          departure: widget.departure,
          destination: widget.destination,
          date: widget.date,
          freeSpaces: widget.freeSpaces,
          departureLat: widget.departureLat,
          departureLon: widget.departureLon,
          destinationLat: widget.destinationLat,
          destinationLon: widget.destinationLon,
          order: _selectedOption.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).orderSelector),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text(translation(context).time),
            leading: Radio<OrderOption>(
              value: OrderOption.time,
              groupValue: _selectedOption,
              onChanged: (OrderOption? value) {
                setState(() {
                  _selectedOption = value;
                });
              },
            ),
          ),
          ListTile(
            title: Text(translation(context).price),
            leading: Radio<OrderOption>(
              value: OrderOption.price,
              groupValue: _selectedOption,
              onChanged: (OrderOption? value) {
                setState(() {
                  _selectedOption = value;
                });
              },
            ),
          ),
          ListTile(
            title: Text(translation(context).departureDistance),
            leading: Radio<OrderOption>(
              value: OrderOption.departureDistance,
              groupValue: _selectedOption,
              onChanged: (OrderOption? value) {
                setState(() {
                  _selectedOption = value;
                });
              },
            ),
          ),
          ListTile(
            title: Text(translation(context).destinationDistance),
            leading: Radio<OrderOption>(
              value: OrderOption.destinationDistance,
              groupValue: _selectedOption,
              onChanged: (OrderOption? value) {
                setState(() {
                  _selectedOption = value;
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _onButtonPressed,
                child: Text(translation(context).verViajes),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
