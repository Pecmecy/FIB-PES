// ignore_for_file: file_names

class MapRoute {
  int id;
  double originLat;
  double originLon;
  String originAlias;
  double destinationLat;
  double destinationLon;
  String destinationAlias;
  String polyline;
  double distance;
  double duration;
  DateTime departureTime;
  int freeSeats;
  double price;
  bool cancelled;
  bool finalized;
  DateTime createdAt;
  int driverId;
  String driverName;
  List<dynamic> waypoints;
  List<int>? passengers;

  MapRoute({
    required this.id,
    required this.originLat,
    required this.originLon,
    required this.originAlias,
    required this.destinationLat,
    required this.destinationLon,
    required this.destinationAlias,
    required this.polyline,
    required this.distance,
    required this.duration,
    required this.departureTime,
    required this.freeSeats,
    required this.price,
    required this.cancelled,
    required this.finalized,
    required this.createdAt,
    required this.driverId,
    required this.driverName,
    required this.waypoints,
    required this.passengers,
  });

  factory MapRoute.fromJson(Map<String, dynamic> json) {
    var driverJson = json['driver'];
    List<dynamic> passengersJson = json['passengers'] as List<dynamic>? ?? [];
    return MapRoute(
      id: json['id'] as int,
      originLat: json['originLat'] as double,
      originLon: json['originLon'] as double,
      originAlias: json['originAlias'] as String,
      destinationLat: json['destinationLat'] as double,
      destinationLon: json['destinationLon'] as double,
      destinationAlias: json['destinationAlias'] as String,
      polyline: json['polyline'] as String,
      distance: (json['distance'] is int)
          ? json['distance'].toDouble()
          : json['distance'] as double,
      duration: (json['duration'] is int)
          ? json['duration'].toDouble()
          : json['duration'] as double,
      departureTime: DateTime.parse(json['departureTime'] as String).toLocal(),
      freeSeats: json['freeSeats'] as int,
      price: json['price'] as double,
      cancelled: json['cancelled'] as bool,
      finalized: json['finalized'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      driverId: driverJson['id'] as int,
      driverName: driverJson['username'] as String,
      waypoints: json['waypoints'] as List<dynamic>,
      passengers: passengersJson.map((e) => e["id"] as int).toList(),
    );
  }

  // Empty constructor
  MapRoute.empty()
      : id = 0,
        originLat = 0,
        originLon = 0,
        originAlias = '',
        destinationLat = 0,
        destinationLon = 0,
        destinationAlias = '',
        polyline = '',
        distance = 0,
        duration = 0,
        departureTime = DateTime.now(),
        freeSeats = 0,
        price = 0,
        cancelled = false,
        finalized = false,
        createdAt = DateTime.now(),
        driverId = 0,
        driverName = '',
        passengers = [],
        waypoints = [];
}
