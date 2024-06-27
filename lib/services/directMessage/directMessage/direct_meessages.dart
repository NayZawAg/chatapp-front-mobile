import 'package:dio/dio.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/direct_message.dart';
import 'package:retrofit/http.dart';

part 'direct_meessages.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio) => _ApiService(dio);

  @GET("$baseUrl/m_users/{userId}")
  Future<DirectMessages> getAllDirectMessages(
      @Path("userId") int userId, @Header('Authorization') String token);

  @POST('$baseUrl/directmsg')
  Future<void> sendMessage(@Body() Map<String, dynamic> requestBody,
      @Header('Authorization') String token);

  @GET('$baseUrl/star')
  Future<void> directStarMsg(
      @Query("s_user_id") int s_user_id,
      @Query("id") int messageId,
      @Query("user_id") int currentUserId,
      @Header('Authorization') String token);

  @GET('$baseUrl/unstar')
  Future<void> directUnStarMsg(
      @Query("id") int starId, @Header('Authorization') String token);

  @GET('$baseUrl/delete_directmsg')
  Future<void> deleteMessage(
      @Query("id") int msgId, @Header('Authorization') String token);
}
