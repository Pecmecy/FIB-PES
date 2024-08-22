class Charger {
  int id;
  double lat;
  double lon;

  Charger(
    this.id,
    this.lat,
    this.lon,
  );

  factory Charger.fromJson(Map<String, dynamic> json) {
    return Charger(
      json['charger'] as int,
      json['latitude'] as double,
      json['longitude'] as double,
    );
  }
}