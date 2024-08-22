import 'package:flutter/material.dart';
import "dart:math" show pi;

// Create a custom triangle
class Triangle extends CustomPainter {
  final Color backgroundColor;
  Triangle(this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = backgroundColor;

    var path = Path();
    path.lineTo(-5, 0);
    path.lineTo(0, 10);
    path.lineTo(5, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

// Sent message bubble
class OutBubble extends StatelessWidget {
  final String message;
  const OutBubble({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(
              color: Colors.indigo.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                bottomLeft: Radius.circular(19),
                bottomRight: Radius.circular(19),
              ),
            ),
            child: RichText(
              text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 15),
              children: <TextSpan>[
                TextSpan(
                  text: message,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                ],
              )
            ),
          ),
        ),
        CustomPaint(painter: Triangle(Colors.indigo.shade600)),
      ],
    );
  }
}

//  Received message bubble
class InBubble extends StatelessWidget {
  final String message;
  final String sender;
  const InBubble({super.key, required this.message, required this.sender});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(pi),
          child: CustomPaint(
            painter: Triangle(Colors.grey.shade300),
          ),
        ),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.only(bottom: 5),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(19),
                bottomLeft: Radius.circular(19),
                bottomRight: Radius.circular(19),
              ),
            ),
            child: RichText(
                text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 15),
              children: <TextSpan>[
                TextSpan(
                    text: ('$sender\n'),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: nameColor(sender),
                        fontSize: 18)),
                TextSpan(
                  text: message,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ],
            )),
          ),
        ),
      ],
    );
  }
}

Color nameColor (String name){
  List<Color> colors = [const Color.fromARGB(255, 255, 127, 170), Colors.lightBlueAccent, const Color.fromARGB(255, 0, 94, 255), Colors.black, Colors.purpleAccent, Colors.red, Colors.green, Colors.orange, const Color.fromARGB(255, 255, 232, 27),];
  int hash = name.hashCode % colors.length;
  return colors[hash];
}