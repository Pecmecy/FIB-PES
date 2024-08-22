class User {
  int id;
  String username;
  String firstName;
  String lastName;
  String email;
  DateTime birthDate;
  String pfp;

  User(
    this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.birthDate,
    this.pfp,
  );

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      json['id'] as int,
      json['username'] as String,
      json['first_name'] as String,
      json['last_name'] as String,
      json['email'] as String,
      DateTime.parse(json['birthDate'] as String)
          .toLocal(), // Parse birthDate string to DateTime
      json['profileImage'] as String,
    );
  }
}
