import 'package:flutter/material.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/classes/language_constants.dart';

class ReportUserPopup extends StatefulWidget {
  final int reportedUserId;

  ReportUserPopup({required this.reportedUserId});

  @override
  _ReportUserPopupState createState() => _ReportUserPopupState();
}

class _ReportUserPopupState extends State<ReportUserPopup> {
  TextEditingController _commentController = TextEditingController();
  final UserController userController = UserController();
  int reporterId = 0;

  @override
  void initState() {
    super.initState();
    _getReporterId();
  }

  void _getReporterId() async {
    reporterId = await userController.usersSelf();
    setState(
        () {}); // Refresh the state to update the UI after getting the reporterId
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(translation(context).motivoReporte),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: translation(context).ingreseMotivoReporte,
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
                      if (reporterId != 0) {
                        // Ensure reporterId is obtained
                        String motivo = _commentController.text;

                        String result = await userController.reportUser(
                            widget.reportedUserId, motivo);

                        // Mostrar el resultado o manejar errores
                        if (result == "") {
                          // Éxito
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(translation(context).reporteExitoso),
                            ),
                          );
                        } else {
                          // Error
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${translation(context).errorReporte}: $result'),
                            ),
                          );
                        }

                        // Cerrar el diálogo
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                translation(context).errorObtenerIdUsuario),
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
      ),
    );
  }
}

// Ejemplo de cómo llamar a ReportUserPopup desde cualquier pantalla
class SomeScreen extends StatelessWidget {
  final int reportedUserId = 123; // Usa el ID adecuado aquí

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Some Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return ReportUserPopup(reportedUserId: reportedUserId);
              },
            );
          },
          child: Text(translation(context).reportarUsuario),
        ),
      ),
    );
  }
}
