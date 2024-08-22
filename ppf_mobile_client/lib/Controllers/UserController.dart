import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ppf_mobile_client/Models/Achivement.dart';
import 'package:ppf_mobile_client/Models/Coment.dart';
import 'package:ppf_mobile_client/Models/Driver.dart';
import 'package:ppf_mobile_client/Models/Users.dart';
import 'package:ppf_mobile_client/config.dart';

class UserController {
  Future<String> logInUser(String email, String password) async {
    try {
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      Response response = await dio
          .post('/login/', data: {"email": email, "password": password});
      if (response.statusCode == 200) {
        dynamic jsonResponse = response.data;
        return jsonResponse["token"] as String;
      }
      tokenFirebase();
      return "";
    } on DioException catch (e) {
      Response? response = e.response;

      //Code 400 error
      if (response?.statusCode == 401) {
        return "Invalid credentials";
      }

      //Other errors
      else {
        return 'Ha ocurrido un error inesperado. Porfavor, intentelo de nuevo más tarde';
      }
    }
  }

  Future<List<User>?> getUsers() async {
    try {
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      Response response = await dio.get('/users/');

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        List<User>? users =
            jsonResponse.map((data) => User.fromJson(data)).toList();
        return users;
      } else {
        return null;
      }

      //Error handling
    } on DioException catch (e) {
      Response? response = e.response;

      //Error code 400
      if (response?.statusCode == 400) {
        return null;
      }

      //Other errors
      else {
        return null;
      }
    }
  }

  Future<String> registerUser(
    String userName,
    String firstName,
    String lastName,
    String mail,
    String pwrd,
    String pwrd2,
    DateTime? birthDate,
  ) async {
    // Parse date
    String formattedDate = DateFormat('yyyy-MM-dd').format(birthDate!.toUtc());

    // API call success
    try {
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      Response response = await dio.post(
        '/users/',
        data: {
          "username": userName,
          "first_name": firstName,
          "last_name": lastName,
          "email": mail,
          "birthDate": formattedDate,
          "password": pwrd,
          "password2": pwrd2,
        },
      );

      // Return empty string if there was no error
      if (response.statusCode == 201) {
        String token = await logInUser(mail, pwrd);
        const storage = FlutterSecureStorage();
        await storage.write(key: 'token', value: token);
        tokenFirebase();
        return response.data['id'].toString();
      } else {
        return 'Ha ocurrido un error inesperado. Por favor, inténtelo de nuevo más tarde';
      }

      // Error handling
    } catch (e) {
      return 'Ha ocurrido un error inesperado. Por favor, inténtelo de nuevo más tarde';
    }
  }

  Future<String> registerDriver(
      String userName,
      String firstName,
      String lastName,
      String mail,
      String pwrd,
      String pwrd2,
      DateTime? birthDate,
      String dni,
      String capacidad,
      List<int> chargerTypes,
      Map<String, bool> preferences,
      String iban) async {
    //To parse a date:
    String formattedDate = DateFormat('yyyy-MM-dd').format(birthDate!.toUtc());

    //API call success
    try {
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      Response response = await dio.post(
        '/drivers/',
        data: {
          "username": userName,
          "first_name": firstName,
          "last_name": lastName,
          "email": mail,
          "birthDate": formattedDate, //formattedDate
          "password": pwrd,
          "password2": pwrd2,
          "dni": dni,
          "autonomy": int.parse(capacidad),
          'chargerTypes': chargerTypes,
          'preference': preferences,
          'iban': iban
        },
      );
      //Return empty string if there was no error
      if (response.statusCode == 201) {
        String token = await logInUser(mail, pwrd);
        const storage = FlutterSecureStorage();
        await storage.write(key: 'token', value: token);
        tokenFirebase();
        return response.data['id'].toString();
      } else {
        return 'Ha ocurrido un error inesperado. Por favor, inténtelo de nuevo más tarde';
      }

      // Error handling
    } catch (e) {
      return 'Ha ocurrido un error inesperado. Por favor, inténtelo de nuevo más tarde';
    }
  }

  Future<int> usersSelf() async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';

      final response = await dio.get('/users/self/');
      int id = response.data['user_id'];
      return id;
    } catch (e) {
      return 0;
    }
  }

  Future<String> putUser(
      String username,
      String first_name,
      String last_name,
      String password,
      String password2,
      DateTime birthDate,
      XFile? imagePath,
      int? id) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';

      String formattedDate = DateFormat('yyyy-MM-dd').format(birthDate.toUtc());

      FormData formData = FormData.fromMap({
        "username": username,
        "first_name": first_name,
        "last_name": last_name,
        if (password != '') "password": password,
        if (password2 != '') "password2": password2,
        "birthDate": formattedDate,
      });

      Response response = await dio.put(
        '/users/$id/',
        data: formData,
      );
      debugPrint(response.data.toString());
      if (imagePath != null) {
        putUserAvatar(imagePath, id);
      }
      return '';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> putUserAvatar(XFile imagePath, int? id) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Token $token';
      dio.options.baseUrl = userApi;

      FormData formData = FormData.fromMap({
        "profileImage": await MultipartFile.fromFile(imagePath.path),
        "id": "$id",
      });
      Response response = await dio.put(
        '/users/$id/avatar',
        data: formData,
      );
      debugPrint(response.data.toString());
      return '';
    } catch (e) {
      return e.toString();
    }
  }

  Future<Driver> getDriverById(int driverId) async {
    Dio dio = Dio();
    dio.options.baseUrl = userApi;
    Response response = await dio.get('/drivers/$driverId');
    if (response.statusCode == 200) {
      return Driver.fromJson(response.data);
    } else {
      throw Exception('Failed to load driver');
    }
  }

  Future<User?> getUserInformation(int id) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');

      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.get('/users/$id/');
      if (response.statusCode == 200) {
        dynamic jsonResponse = response.data;
        return User.fromJson(jsonResponse);
      } else {
        return null;
      }
    } on DioException catch (e) {
      Response? response = e.response;

      //Error code 400
      if (response?.statusCode == 400) {
        return null;
      }

      //Other errors
      else {
        return null;
      }
    }
  }

  Future<List<SimpleAchievement>> getUserAchievements(int id) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      if (token == null) {
        return [];
      }

      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.get('/users/$id/achievements/');
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        return jsonResponse
            .map((data) => SimpleAchievement.fromJson(data))
            .toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      Response? response = e.response;
      if (response != null) {
        if (response.statusCode == 400) {
          return [];
        }
      }
      return [];
    } catch (e) {
      debugPrint("Exception: $e");
      return [];
    }
  }

  Future<List<Comment>> getUserComments(int id) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');

      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.get('/users/$id/valuations/');
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        List<Comment> comments = [];
        for (var singleComment in jsonResponse) {
          try {
            comments.add(Comment.fromJson(singleComment));
          } catch (e) {
            print('Error $e');
          }
        }
        return comments;
      } else {
        return [];
      }
    } on DioException catch (e) {
      Response? response = e.response;

      if (response != null) {
        if (response.statusCode == 400) {
          return [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Comment>> getUserCommentsId(int id) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');

      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.get('/users/$id/valuations/');
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        return jsonResponse.map((data) => Comment.fromJson(data)).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      Response? response = e.response;

      if (response != null) {
        if (response.statusCode == 400) {
          return [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<String> submitRouteRating(Comment rating) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';

      // Crear el cuerpo de la solicitud utilizando el método toJson del modelo Comment
      final data = rating.toJson();

      // Enviar la solicitud POST
      final response = await dio.post('/valuate/', data: data);

      if (response.statusCode == 201) {
        return ''; // Éxito
      } else {
        return 'Ha ocurrido un error inesperado. Por favor, intenta de nuevo más tarde.';
      }
    } catch (e) {
      return 'Ha ocurrido un error: $e';
    }
  }

  Future<Driver?> getDriverInformation(int id) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');

      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.get('/drivers/$id/');
      if (response.statusCode == 200) {
        dynamic jsonResponse = response.data;
        return Driver.fromJson(jsonResponse);
      } else {
        return null;
      }
    } on DioException catch (e) {
      Response? response = e.response;

      //Error code 400
      if (response?.statusCode == 400) {
        return null;
      }

      //Other errors
      else {
        return null;
      }
    }
  }

  Future<bool> loginWithGoogle() async {
    var googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      return false;
    }

    var data = {
      'displayName': googleUser.displayName,
      'email': googleUser.email,
      'photoUrl': googleUser.photoUrl,
    };

    await GoogleSignIn().signOut();

    try {
      const storage = FlutterSecureStorage();
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      Response response = await dio.post('/login/google', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await storage.write(key: 'token', value: response.data['token']);
      }

      if (kDebugMode) {
        print('Response Data:');
        print(response.data);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error:');
        print(e);
      }
    }
    return false;
  }

  Future<bool> syncWithCalendar() async {
    // Configure GoogleSignIn with the required scopes and requestServerAuthCode

    GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'profile',
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/userinfo.email',
        'https://www.googleapis.com/auth/calendar.events.owned',
        'https://www.googleapis.com/auth/calendar',
        'openid',
      ],
      serverClientId:
          "594492029703-c83c213hi72rjrohe7fppo2dn1o3pcid.apps.googleusercontent.com",
      forceCodeForRefreshToken: true,
    );

    var googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return false;
    }

    var auth = await googleUser.authentication;

    var data = {
      'displayName': googleUser.displayName,
      'email': googleUser.email,
      'photoUrl': googleUser.photoUrl,
      'id': googleUser.id,
      'serverAuthCode': googleUser.serverAuthCode,
      'accessToken': auth.accessToken,
      'idToken': auth.idToken,
    };

    await googleSignIn.signOut();

    if (kDebugMode) {
      print('Google User Data:');
      print('Display Name: ${data['displayName']}');
      print('Email: ${data['email']}');
      print('Photo URL: ${data['photoUrl']}');
      print('ID: ${data['id']}');
      print('Server Auth Code: ${data['serverAuthCode']}');
      print('Access Token: ${data['accessToken']}');
      print('ID Token: ${data['idToken']}');
    }
    data = {'code': data['serverAuthCode']};
    print('somethin in here!!!!');
    print(data);
    try {
      const storage = FlutterSecureStorage();
      Dio dio = Dio();
      String? token = await storage.read(key: 'token');
      dio.options.headers['Authorization'] = 'Token $token';
      dio.options.baseUrl = routeApi;
      Response response = await dio.post('/calendar_token', data: data);
      print('Response Data:');
      print(response.data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(msg: "Calendar successfully synchronized");
      }
      if (kDebugMode) {
        print('Response Data:');
        print(response.data['error']);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
    return false;
  }

  Future<String> changePasswaord(String email) async {
    try {
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      Response response = await dio.post('/reset-password/', data: {
        "email": email,
      });
      if (response.statusCode == 200) {
        return "";
      } else {
        return "Ha ocurrido un error inesperado. Por favor, inténtelo de nuevo más tarde";
      }
    } on DioException catch (e) {
      Response? response = e.response;

      //Code 400 error
      if (response?.statusCode == 400) {
        return "El correo electrónico no está registrado en el sistema";
      }

      //Other errors
      else {
        return 'Ha ocurrido un error inesperado. Porfavor, intentelo de nuevo más tarde';
      }
    }
  }

  void tokenFirebase() async {
    try {
      int id = await usersSelf();
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';
      String? firebaseToken = await storage.read(key: 'firebaseToken');
      Response response = await dio.post(
        '/push/register/$id',
        data: {"token": firebaseToken},
      );
      debugPrint(response.data.toString());
      return;
    } catch (e) {
      debugPrint(e.toString());
      return;
    }
  }

  Future<String> deleteUser(int id) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');

      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.delete('/users/$id/');
      if (response.statusCode == 204) {
        return '';
      } else {
        return 'Ha ocurrido un error inesperado. Porfavor, intentelo de nuevo más tarde';
      }
    } on DioException catch (e) {
      Response? response = e.response;

      //Error code 400
      if (response?.statusCode == 404) {
        return 'User not found';
      }

      //Other errors
      else {
        return 'Ha ocurrido un error inesperado. Porfavor, intentelo de nuevo más tarde';
      }
    }
  }

  Future<String> deleteDriver(int id) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');

      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.delete('/drivers/$id/');
      if (response.statusCode == 204) {
        return '';
      } else {
        return 'Ha ocurrido un error inesperado. Porfavor, intentelo de nuevo más tarde';
      }
    } on DioException catch (e) {
      Response? response = e.response;

      //Error code 400
      if (response?.statusCode == 404) {
        return 'Driver not found';
      }

      //Other errors
      else {
        return 'Ha ocurrido un error inesperado. Porfavor, intentelo de nuevo más tarde';
      }
    }
  }

  Future<String> putDriver(
    String username,
    String first_name,
    String last_name,
    String password,
    String password2,
    DateTime birthDate,
    String autonomy,
    List<int> chargerTypes,
    Map<String, bool> preferences,
    String iban,
    int id,
  ) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';

      String formattedDate = DateFormat('yyyy-MM-dd').format(birthDate);

      /*ByteData imageData = await rootBundle.load(imagePath);
      List<int> imageBytes = imageData.buffer.asUint8List();*/

      //print(preferences);
      Response response = await dio.put(
        '/drivers/$id/',
        data: {
          "username": username,
          "first_name": first_name,
          "last_name": last_name,
          if (password != '') "password": password,
          if (password2 != '') "password2": password2,
          "birthDate": formattedDate,
          "autonomy": int.parse(autonomy),
          "chargerTypes": chargerTypes,
          "preference": preferences,
          "iban": iban,
        },
      );
      debugPrint(response.data.toString());
      return '';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> userToDriver(
      String dni,
      String capacidad,
      List<int> chargerTypes,
      Map<String, bool> preferences,
      String iban) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.post(
        '/user-to-driver/',
        data: {
          "dni": dni,
          "autonomy": int.parse(capacidad),
          'chargerTypes': chargerTypes,
          'preferences': preferences,
          'iban': iban
        },
      );
      if (response.statusCode == 200) {
        await storage.delete(key: 'token');
        return '';
      } else {
        return 'Ha ocurrido un error inesperado. Porfavor, intentelo de nuevo más tarde';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> driverToUser() async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.post('/driver-to-user/');
      if (response.statusCode == 200) {
        await storage.delete(key: 'token');
        return '';
      } else {
        return 'Ha ocurrido un error inesperado. Porfavor, intentelo de nuevo más tarde';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Comment>> getOtherUserComments(int id) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');

      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.get('/users/$id/valuations/');
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        return jsonResponse.map((data) => Comment.fromJson(data)).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      Response? response = e.response;

      if (response != null) {
        if (response.statusCode == 400) {
          return [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<String?> getUserProfileImage(int userId) async {
    try {
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.get('/users/$userId/');
      if (response.statusCode == 200) {
        return response.data['profileImage'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<double?> getUserValoration(int userId) async {
    try {
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      dio.options.headers['Authorization'] = 'Token $token';
      Response response = await dio.get('/users/$userId/valuations/');
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = response.data;
        if (jsonResponse.isEmpty) return null;
        double sum = 0;
        jsonResponse.forEach((data) {
          Comment comment = Comment.fromJson(data);
          sum += comment.rating.toDouble(); // Convertir el rating a double
        });
        return sum / jsonResponse.length;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String> reportUser(int reportedUserId, String comment) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'token');
      Dio dio = Dio();
      dio.options.baseUrl = userApi;
      dio.options.headers['Authorization'] = 'Token $token';

      Response response = await dio.post(
        '/reports/',
        data: {
          "reported": reportedUserId.toString(),
          "comment": comment,
        },
      );

      if (response.statusCode == 201) {
        return 'Reporte enviado con éxito.';
      } else {
        return 'Ha ocurrido un error inesperado. Por favor, intenta de nuevo más tarde.';
      }
    } catch (e) {
      return 'Ha ocurrido un error: $e';
    }
  }
}

final userController = UserController();
