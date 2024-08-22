class SimpleAchievement {
  final String title;
  final bool achieved;
  final String date;

  SimpleAchievement({
    required this.title,
    required this.achieved,
    required this.date,
  });

  factory SimpleAchievement.fromJson(Map<String, dynamic> json) {
    return SimpleAchievement(
      title: json['title'],
      achieved: json['achieved'],
      date: json['achieved'] ? json['date_achieved'] : 'N/A',
    );
  }
}
