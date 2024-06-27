import 'package:dio/dio.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:retrofit/http.dart';

part 'm_channel_service.g.dart';

@RestApi(baseUrl: '$baseUrl')
abstract class MChannelService {
  factory MChannelService(Dio dio) => _MChannelService(dio);

  @POST('/m_channels')
  Future<void> createMChannel(
      @Body() Map<String, dynamic> body, @Header('Authorization') String token);

  @DELETE('/m_channels/{channelID}')
  Future<void> deleteChannel(
      @Part() int channelID, @Header('Authorization') String token);

  @PATCH('/m_channels/{channelId}')
  Future<String> updateChannel(@Path() int channelId,
      @Body() Map<String, dynamic> body, @Header('Authorization') String token);

  @GET('/channeluserjoin')
  Future<String> joinChannel(@Query('user_id') int userID,@Query('channel_id') int channelId,
      @Header('Authorization') String token);
  
  
}

