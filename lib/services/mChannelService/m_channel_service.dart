import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';

part 'm_channel_service.g.dart';

@RestApi()
abstract class MChannelService {
  factory MChannelService(Dio dio) => _MChannelService(dio);

  @POST('https://cmmteam3-backend-api.onrender.com/m_channels')
  Future<void> createMChannel(
      @Body() Map<String, dynamic> body, @Header('Authorization') String token);

  @DELETE('https://cmmteam3-backend-api.onrender.com/m_channels/{channelID}')
  Future<void> deleteChannel(
      @Part() int channelID, @Header('Authorization') String token);

  @PATCH('https://cmmteam3-backend-api.onrender.com/m_channels/{channelId}')
  Future<String> updateChannel(@Path() int channelId,
      @Body() Map<String, dynamic> body, @Header('Authorization') String token);

  @GET('https://cmmteam3-backend-api.onrender.com/channeluserjoin')
  Future<String> joinChannel(@Query('user_id') int userID,@Query('channel_id') int channelId,
      @Header('Authorization') String token);
  
  
}
