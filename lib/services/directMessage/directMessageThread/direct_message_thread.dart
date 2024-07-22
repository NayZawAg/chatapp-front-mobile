import 'package:dio/dio.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/direct_message_thread.dart';
import 'package:retrofit/http.dart';

part 'direct_message_thread.g.dart';

@RestApi()
abstract class DirectMsgThreadService {
  factory DirectMsgThreadService(Dio dio) => _DirectMsgThreadService(dio);

  @GET('$baseUrl/directhread/{directMsgid}')
  Future<DirectMessageThread> getAllThread(
      @Path() int directMsgid, @Header('Authorization') String token);

  @POST('$baseUrl/directthreadmsg')
  Future<String> sentThread(@Body() Map<String, dynamic> requestBody,
      @Header('Authorization') String token);

  @GET('$baseUrl/starthread')
  Future<void> starThread(
      @Query('s_user_id') int receiveId,
      @Query('user_id') int currentUserid,
      @Query('id') int threadId,
      @Query('s_direct_message_id') int directMessageId,
      @Header('Authorization') String token);

  @GET('$baseUrl/unstarthread')
  Future<void> unStarThread(
      @Query('s_direct_message_id') int directMsgId,
      @Query('s_user_id') int receiveId,
      @Query('id') int threadId,
      @Query('user_id') int userId,
      @Header('Authorization') String token);

  @GET('$baseUrl/delete_directthread')
  Future<void> deleteThread(
      @Query('s_direct_message_id') int directMsgId,
      @Query('s_user_id') int receiveUserId,
      @Query('id') int threadId,
      @Header('Authorization') String token);

  @POST('$baseUrl/update_directthreadmsg')
  Future<void> editdirectThreadMessage(@Body() Map<String, dynamic> requestBody,
      @Header('Authorization') String token);

  @POST('$baseUrl/directthreadreact')
  Future<void> directThreadMessageReaction(
      @Body() Map<String, dynamic> requestBody,
      @Header('Authorization') String token);
}
