class SimpleRoute {
  int id;
  int driverId;
  String driverName;
  String originAlias;
  String destinationAlias;
  String polyline;
  double distance;
  double duration;
  DateTime departureTime;
  int freeSeats;
  double price;
  double distanceOrigin;
  double distanceDestination;
  bool finalized;
  List<int> passengers;

  SimpleRoute({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.originAlias,
    required this.destinationAlias,
    required this.polyline,
    required this.distance,
    required this.duration,
    required this.departureTime,
    required this.freeSeats,
    required this.price,
    required this.distanceOrigin,
    required this.distanceDestination,
    required this.finalized,
    required this.passengers,
  });

  factory SimpleRoute.fromJson(Map<String, dynamic> json) {
    var driverJson = json['driver'];
    var passengersJson = json['passengers'] as List<dynamic>? ?? [];
    return SimpleRoute(
      id: json['id'] as int,
      driverId: driverJson['id'] as int,
      driverName: driverJson['username'] as String,
      originAlias: json['originAlias'] as String? ?? '',
      destinationAlias: json['destinationAlias'] as String? ?? '',
      polyline: json['polyline'] as String? ?? '',
      distance: (json['distance'] is int)
          ? (json['distance'] as int).toDouble()
          : (json['distance'] as double? ?? 0),
      duration: (json['duration'] is int)
          ? (json['duration'] as int).toDouble()
          : (json['duration'] as double? ?? 0),
      departureTime: DateTime.parse(json['departureTime'] as String),
      freeSeats: json['freeSeats'] as int? ?? 0,
      price: json['price'] as double? ?? 0,
      distanceOrigin: (json['originDistance'] is int)
          ? (json['originDistance'] as int).toDouble()
          : (json['originDistance'] as double? ?? 0),
      distanceDestination: (json['destinationDistance'] is int)
          ? (json['destinationDistance'] as int).toDouble()
          : (json['destinationDistance'] as double? ?? 0),
      finalized: json['finalized'] as bool,
      passengers: passengersJson.map((e) => e["id"] as int).toList(),
    );
  }

  // Empty constructor
  SimpleRoute.empty()
      : id = 0,
        driverId = 0,
        driverName = '',
        originAlias = '',
        destinationAlias = '',
        polyline = '',
        distance = 0,
        duration = 0,
        departureTime = DateTime.now(),
        freeSeats = 0,
        price = 0,
        distanceOrigin = 0,
        distanceDestination = 0,
        finalized = false,
        passengers = List<int>.empty();
}
