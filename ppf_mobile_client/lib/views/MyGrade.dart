import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/Models/Coment.dart';
import 'package:ppf_mobile_client/Models/Users.dart';
import 'package:ppf_mobile_client/global_widgets/MyProfileNavigation.dart';
import 'package:ppf_mobile_client/global_widgets/NavigationBar.dart';

class MyGrade extends StatefulWidget {
  final int id;
  final bool isLoggedUser;
  const MyGrade({super.key, required this.id, required this.isLoggedUser});

  @override
  _MyGradeState createState() => _MyGradeState();
}

class _MyGradeState extends State<MyGrade> {
  List<Comment> reviews = [];
  Map<int, User> userMap = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getComments();
  }

  void getComments() async {
    List<Comment> comments = await UserController().getUserComments(widget.id);
    for (var comment in comments) {
      User? user = await UserController().getUserInformation(comment.giver);
      if (user != null) {
        userMap[comment.giver] = user;
      }
    }
    setState(() {
      reviews = comments;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: MyProfileNavigation(
          selectedIndex: 1, id: widget.id, isLoggedUser: widget.isLoggedUser),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : reviews.isEmpty
              ? Center(child: Text(localizations!.noReviews))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: RatingSummary(reviews: reviews),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          Comment review = reviews[index];
                          User? user = userMap[review.giver];
                          return ReviewCard(
                            review: review,
                            username: user?.username ?? localizations!.unknown,
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: Bar(selectedIndex: widget.isLoggedUser ? 4 : 0),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Comment review;
  final String username;

  const ReviewCard({Key? key, required this.review, required this.username})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
                SizedBox(width: 8),
                Text(username),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                StarRating(rating: review.rating.toDouble()),
                SizedBox(width: 4),
                Text('${review.rating}'),
              ],
            ),
            SizedBox(height: 8),
            Text(review.comment),
          ],
        ),
      ),
    );
  }
}

class RatingSummary extends StatelessWidget {
  final List<Comment> reviews;

  const RatingSummary({Key? key, required this.reviews}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);
    double totalRating = 0;
    for (var review in reviews) {
      totalRating += review.rating;
    }
    double averageRating =
        reviews.isNotEmpty ? totalRating / reviews.length : 0.0;

    return Column(
      children: [
        Text(
          localizations!.averageRating,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        StarRating(rating: averageRating),
        SizedBox(height: 8),
        Text(
          '(${averageRating.toStringAsFixed(1)})',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;

  const StarRating({Key? key, required this.rating, this.starCount = 5})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        starCount,
        (index) {
          if (index < rating) {
            return Icon(Icons.star, color: Colors.amber);
          } else {
            return Icon(Icons.star_border, color: Colors.grey);
          }
        },
      ),
    );
  }
}
