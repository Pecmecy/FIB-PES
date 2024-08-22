import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ppf_mobile_client/Controllers/UserController.dart';
import 'package:ppf_mobile_client/Models/BasicRoute.dart';
import 'package:ppf_mobile_client/Models/Route.dart';
import 'package:ppf_mobile_client/Models/RouteData.dart';
import 'package:ppf_mobile_client/Models/Users.dart';
import 'package:ppf_mobile_client/config.dart';

class RouteController {
  Future<String> registerRoute(
      String departure,
      double departureLatitude,
      double departureLongitude,
      String destination,
      double destinationLatitude,
      double destinationLongitude,
      DateTime? selectedDate,
      String freeSpaces,
      String price) async {
    String formattedDate =
        DateFormat('yyyy-MM-ddThh:mm:ss').format(selectedDate!.toLocal());

    //API call success
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = routeApi;
      dio.options.headers['Authorization'] = 'Token $token';
      debugPrint(
          'token: $token, departureLatitude: $departureLatitude, departureLongitude: $departureLongitude, destinationLatitude: $destinationLatitude, destinationLongitude: $destinationLongitude, departure: $departure, destination: $destination, formattedDate: $formattedDate, freeSpaces: $freeSpaces, price: $price');
      Response response = await dio.post(
        '/routes',
        data: {
          "originLat": departureLatitude,
          "originLon": departureLongitude,
          "originAlias": departure,
          "destinationLat": destinationLatitude,
          "destinationLon": destinationLongitude,
          "destinationAlias": destination,
          "departureTime": formattedDate,
          "freeSeats": int.parse(freeSpaces),
          "price": double.parse(price)
        },
      );

      //Return empty string if there was no error
      if (response.statusCode == 201) {
        return '';
      } else {
        return 'Ha ocurrido un error inesperado. Porfavor, intentelo de nuevo más tarde';
      }

      //Error handling
    } on DioException catch (e) {
      Response? response = e.response;

      //Error code 400
      if (response?.statusCode == 404) {
        return '$response';
      }

      //Other errors
      else {
        return 'Ha ocurrido un error inesperado. Porfavor, intentelo de nuevo más tarde';
      }
    }
  }

  Future<List<SimpleRoute>> getRoutes(
      double departureLat,
      double departureLon,
      double destinationLat,
      double destinationLon,
      DateTime departureTime,
      String freeSpaces,
      int pageSize,
      int page) async {
    try {
      Dio dio = Dio();
      dio.options.baseUrl = routeApi;

      String formattedDate =
          DateFormat('yyyy-MM-dd').format(departureTime.toLocal());
      String location =
          "$departureLat, $departureLon, $destinationLat, $destinationLon";
      var response = await dio.get('/v2/routes', queryParameters: {
        "location": location,
        "date": formattedDate,
        "seats": freeSpaces,
        "page": page,
        "page_size": pageSize,
      });

      if (response.statusCode == 200) {
        List<dynamic> jsonRoutes = response.data['results'];
        List<SimpleRoute> routes = [];

        for (var jsonRoute in jsonRoutes) {
          SimpleRoute route = SimpleRoute.fromJson(jsonRoute);
          routes.add(route);
        }
        return routes;
      } else {
        // Handle unsuccessful response
        throw Exception('Failed to load routes');
      }
    } on DioException catch (e) {
      // Handle Dio errors
      debugPrint(e.error as String?);
      throw Exception('Failed to load routes');
    }
  }

  Future<List<SimpleRoute>> getUserRoutes(int id) async {
    try {
      Dio dio = Dio();
      dio.options.baseUrl = routeApi;
      var response = await dio.get('/v2/routes', queryParameters: {
        "user": id,
        "include": "finalized",
      });

      if (response.statusCode == 200) {
        List<dynamic> jsonRoutes = response.data['results'];
        List<SimpleRoute> routes = [];

        for (var jsonRoute in jsonRoutes) {
          SimpleRoute route = SimpleRoute.fromJson(jsonRoute);
          routes.add(route);
        }

        return routes;
      } else {
        // Handle unsuccessful response
        throw Exception('Failed to load routes');
      }
    } on DioException catch (e) {
      // Handle Dio errors
      debugPrint(e.error as String?);
      throw Exception('Failed to load routes');
    }
  }

  Future<bool> isUserinRoute(int idRoute) async {
    int idUser = await userController.usersSelf();
    List<SimpleRoute> rutas = await getUserRoutes(idUser);
    bool cosa = false;
    for (SimpleRoute route in rutas) {
      if (route.id == idRoute) {
        cosa = true;
      }
    }
    return cosa;
  }

  Future<List<User>> getRoutePassengers(int routeId) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = routeApi;
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.get('/routes/$routeId/passengers');

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        List<User> passengers = [];
        for (var passengerData in jsonResponse) {
          int userId = passengerData['id'];
          User? user = await userController.getUserInformation(userId);
          if (user != null) {
            passengers.add(user);
          }
        }
        return passengers;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<MapRoute> getMapRoute(int routeId) async {
    try {
      var id = routeId.toString();
      Dio dio = Dio();
      dio.options.baseUrl = routeApi;

      var response = await dio.get('/routes/$id');

      // Check if response is successful
      if (response.statusCode == 200) {
        // Parse JSON response
        var json = response.data;

        // Create MapRoute object from JSON using factory method
        MapRoute mapRoute =
            MapRoute.fromJson(json); //MapRoute.fromJson(responseData);

        // Return the created MapRoute object
        return mapRoute;
      } else {
        // Handle unsuccessful response
        throw Exception('Failed to load route');
      }
    } on DioException catch (e) {
      // Handle Dio errors
      debugPrint(e.error as String?);
      throw Exception('Failed to load route');
    }
  }

  Future<RouteData> getRouteBetweenCoordinates(
    double departureLatitude,
    double departureLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    // API call success
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token is null');
      }

      Dio dio = Dio();
      dio.options.baseUrl = routeApi;
      dio.options.headers['Authorization'] = 'Token $token';
      debugPrint(
        'token: $token, departureLatitude: $departureLatitude, departureLongitude: $departureLongitude, destinationLatitude: $destinationLatitude, destinationLongitude: $destinationLongitude',
      );

      Response response = await dio.post(
        '/routes/preview',
        data: {
          "originLat": departureLatitude,
          "originLon": departureLongitude,
          "destinationLat": destinationLatitude,
          "destinationLon": destinationLongitude,
        },
      );

      RouteData routeData = RouteData.fromJson(response.data);
      return routeData;
    } catch (e) {
      debugPrint('Exception: ${e.toString()}');
      return RouteData(polyline: [], chargers: []);
    }
  }

  Future<bool> validateJoinToRoute(int routeId) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      var id = routeId.toString();
      Dio dio = Dio();
      dio.options.baseUrl = routeApi;
      dio.options.headers['Authorization'] = 'Token $token';
      var response = await dio.post('/routes/$id/validate_join');

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        // Handle unsuccessful response
        return false;
      }
    } on DioException catch (e) {
      // Handle Dio errors
      debugPrint(e.error as String?);
      throw Exception('Failed to join the route');
    }
  }

  Future<bool> finishRoute(int routeId) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      var id = routeId.toString();
      Dio dio = Dio();
      dio.options.baseUrl = routeApi;
      dio.options.headers['Authorization'] = 'Token $token';
      var response = await dio.post('/routes/$id/finish');

      // Check if response is successful
      if (response.statusCode == 200) {
        return true;
      } else {
        // Handle unsuccessful response
        return false;
      }
    } on DioException catch (e) {
      // Handle Dio errors
      debugPrint(e.error as String?);
      throw Exception('Failed to finish the route');
    }
  }

  Future<String> leaveRoute(int routeId) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = routeApi;
      dio.options.headers['Authorization'] = 'Token $token';
      dio.post('/routes/$routeId/leave');
      return '';
    } catch (e) {
      debugPrint('Exception: ${e.toString()}');
      return e.toString();
    }
  }

  Future<String> joinRoute(String paymentMethodId, int routeId) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = routeApi;
      dio.options.headers['Authorization'] = 'Token $token';
      var response = await dio.post('/routes/$routeId/join', data: {
        "payment_method_id": paymentMethodId,
      });
      debugPrint(response.data.toString());
      return '';
    } catch (e) {
      debugPrint('Exception: ${e.toString()}');
      return e.toString();
    }
  }

  Future<Map<String, dynamic>> getPolyline(
      LatLng origin, LatLng destination) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      var originLat = origin.latitude;
      var originLon = origin.longitude;
      var destinationLat = destination.latitude;
      var destinationLon = destination.longitude;
      Dio dio = Dio();
      dio.options.baseUrl = routeApi;
      dio.options.headers['Authorization'] = 'Token $token';

      var response = await dio.post('/routes/preview', data: {
        "originLat": originLat,
        "originLon": originLon,
        "destinationLat": destinationLat,
        "destinationLon": destinationLon,
      });

      if (kDebugMode) {
        print('polyline: ${response.data['polyline']}');
        print('waypoints: ${response.data['waypoints']}');
      }

      // Parse charger points
      List<LatLng> chargers = [];
      if (response.data['waypoints'] != null) {
        chargers = (response.data['waypoints'] as List<dynamic>)
            .map((item) => LatLng(item['latitude'], item['longitude']))
            .toList();
      }

      // Decode polyline points
      List<LatLng> polylinePoints = [];
      if (response.data['polyline'] != null &&
          response.data['polyline'] is String) {
        polylinePoints = PolylinePoints()
            .decodePolyline(response.data['polyline'])
            .map((e) => LatLng(e.latitude, e.longitude))
            .toList();
      }

      return {
        "polyline": Polyline(
          polylineId: const PolylineId('polyline'),
          color: Colors.blue,
          points: polylinePoints,
          width: 5,
        ),
        "chargers": chargers,
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException: ${e.message}');
      }
      throw Exception('Failed to get polyline');
    } catch (e) {
      if (kDebugMode) {
        print('Exception: $e');
      }
      throw Exception('Failed to get polyline');
    }
  }

  Future<String> reportCharger(int chargerId) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = routeApi;
      dio.options.headers['Authorization'] = 'Token $token';
      var response = await dio.post('/chargers/$chargerId/report');
      if (response.statusCode == 201) {
        return '';
      } else {
        return 'Ha ocurrido un error inesperado. Porfavor, intentelo de nuevo más tarde';
      }
    } on DioException catch (e) {
      Response? response = e.response;

      //Error code 400
      if (response?.statusCode == 404) {
        return 'No se ha encontrado el cargador seleccionado';
      }

      if (response?.statusCode == 400) {
        return 'Ha habido un error al reportar el cargador';
      }

      //Other errors
      else {
        return 'Ha ocurrido un error inesperado. Porfavor, intentelo de nuevo más tarde';
      }
    }
  }
}

final routeController = RouteController();
