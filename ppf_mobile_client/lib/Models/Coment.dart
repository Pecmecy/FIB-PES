class Comment {
  final int giver;
  final int receiver;
  final int rating;
  final String comment;
  final int? route;

  Comment({
    required this.giver,
    required this.receiver,
    required this.rating,
    required this.comment,
    required this.route,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      giver: json['giver'],
      receiver: json['receiver'],
      rating: json['rating'],
      comment: json['comment'],
      route: json['route'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'giver': giver,
      'receiver': receiver,
      'rating': rating,
      'comment': comment,
      'route': route,
    };
  }
}
