import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:ppf_mobile_client/config.dart';

class GoogleAPIController {
  Future<List<dynamic>> makeSuggestionRemote(
      String input, String tokenForSession) async {
    Dio dio = Dio();
    String googlePlacesApiKey = GOOGLE_MAPS_API_KEY;
    String groundURL =
        'https://maps.googleapis.com/maps/api/place/queryautocomplete/json';

    try {
      var responseResult = await dio.get(groundURL, queryParameters: {
        'input': input,
        'key': googlePlacesApiKey,
        'sessiontoken': tokenForSession
      });

      return jsonDecode(responseResult.toString())['predictions'];
    } on DioException catch (e) {
      List<dynamic> emptyList = [e];
      return emptyList;
    }
  }
}

final googleAPIController = GoogleAPIController();
