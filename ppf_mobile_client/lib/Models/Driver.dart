class Driver {
  int id;
  String userName;
  String firstName;
  String lastName;
  String email;
  int driverPoints;
  String pfp;
  int autonomy;
  List<bool> chargerTypes;
  Map<String, bool> preferences;
  String IBAN;
  String profileImage;

  Driver(
    this.id,
    this.userName,
    this.firstName,
    this.lastName,
    this.email,
    this.driverPoints,
    this.pfp,
    this.autonomy,
    this.chargerTypes,
    this.preferences,
    this.IBAN,
    this.profileImage,
  );

  factory Driver.fromJson(Map<String, dynamic> json) {
    List<bool> _chargerTypes = [false, false, false, false, false];
    List<dynamic> aux = json['chargerTypes'] as List<dynamic>;
    aux.forEach((item) {
      if (item == 1) _chargerTypes[0] = true;
      if (item == 2) _chargerTypes[1] = true;
      if (item == 3) _chargerTypes[2] = true;
      if (item == 4) _chargerTypes[3] = true;
      if (item == 5) _chargerTypes[4] = true;
    });

    Map<String, dynamic> aux2 = json['preference'] as Map<String, dynamic>;
    aux2.remove("id");

    return Driver(
        json['id'] as int,
        json['username'] as String,
        json['first_name'] as String,
        json['last_name'] as String,
        json['email'] as String,
        json['driverPoints'] as int,
        json['profileImage'] as String,
        json['autonomy'] as int,
        _chargerTypes,
        Map<String, bool>.from(aux2),
        json['iban'] as String,
        json['profileImage'] as String);
  }

  static Driver empty() {
    return Driver(
      3,
      '',
      '',
      '',
      '',
      0,
      '',
      0,
      [],
      {},
      '',
      '',
    );
  }
}
