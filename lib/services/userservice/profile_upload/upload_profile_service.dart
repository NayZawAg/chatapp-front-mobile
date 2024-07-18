import 'package:dio/dio.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/profileImage.dart';
import 'package:retrofit/http.dart';

part 'upload_profile_service.g.dart';

@RestApi(baseUrl: baseUrl)
abstract class UploadProfileService {

  factory UploadProfileService(Dio dio) => _UploadProfileService(dio);

  @POST('/profile_update')
  Future<ProfileImage> uploadProfile(@Body() Map<String, dynamic> requestBody,
      @Header('Authorization') String token);
}