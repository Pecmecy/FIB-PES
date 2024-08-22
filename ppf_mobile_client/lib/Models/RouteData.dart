import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:ppf_mobile_client/Models/Charger.dart';

class RouteData {
  List<PointLatLng> polyline;
  List<Charger> chargers;

  RouteData({
    required this.polyline,
    required this.chargers,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    var chargersJson = json['waypoints'] as List;
    List<Charger> chargers =
        chargersJson.map((charger) => Charger.fromJson(charger)).toList();
    List<PointLatLng> polyline =
        PolylinePoints().decodePolyline(json['polyline']);
    return RouteData(
      polyline: polyline,
      chargers: chargers,
    );
  }
}
