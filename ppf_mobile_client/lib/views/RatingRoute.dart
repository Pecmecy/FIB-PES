import 'package:flutter/material.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/Models/Coment.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';

class RatingPopup extends StatefulWidget {
  final int receiver;
  final int route;

  RatingPopup({required this.receiver, required this.route});

  @override
  _RatingPopupState createState() => _RatingPopupState();
}

class _RatingPopupState extends State<RatingPopup> {
  int _rating = 0;
  TextEditingController _commentController = TextEditingController();
  final UserController userController = UserController();
  int giverId = 0;

  @override
  void initState() {
    super.initState();
    getid();
  }

  void getid() async {
    giverId = await userController.usersSelf();
    setState(
        () {}); // Refresh the state to update the UI after getting the giverId
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            Text(translation(context).comentario),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: translation(context).ingreseComentario,
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    if (giverId != 0) {
                      // Ensure giverId is obtained
                      Comment rating = Comment(
                        giver: giverId,
                        receiver: widget.receiver,
                        route: widget.route,
                        rating: _rating,
                        comment: _commentController.text,
                      );

                      String result =
                          await userController.submitRouteRating(rating);

                      // Mostrar el resultado o manejar errores
                      if (result == "") {
                        // Éxito
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text(translation(context).calificacionExitosa),
                          ),
                        );
                      } else {
                        // Error
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${translation(context).errorCalificacion}: $result'),
                          ),
                        );
                      }

                      // Cerrar el diálogo
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(translation(context).errorObtenerId),
                        ),
                      );
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color(0xFF42AB49)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                  child: Text(
                    translation(context).enviar,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
