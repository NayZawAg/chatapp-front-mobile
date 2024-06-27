
import 'package:dio/dio.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:retrofit/http.dart';

part 'login_change_service.g.dart';

@RestApi(baseUrl: '$baseUrl/m_users')
abstract class MuserService {
  factory MuserService(Dio dio) => _MuserService(dio);

  @POST('')
  Future<dynamic> createUser(@Body() Map<String, dynamic> body);

  @PATCH('/{currentUserId}')
  Future<dynamic> changePassword(@Path('currentUserId') int currentUserId,
      @Body() Map<String, dynamic> body, @Header('Authorization') String token);
}
