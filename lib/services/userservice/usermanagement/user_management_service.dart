import 'package:dio/dio.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/user_management.dart';
import 'package:retrofit/http.dart';

part 'user_management_service.g.dart';

@RestApi(baseUrl: baseUrl)
abstract class UserManagementService {
  factory UserManagementService(Dio dio) => _UserManagementService(dio);

  @GET('/usermanage')
  Future<UserManagement> getAllUser(@Header('Authorization') String token);

  @GET('/update')
  Future<String> deactivateUser(
      @Query('id') int userID, @Header('Authorization') String token);
}
