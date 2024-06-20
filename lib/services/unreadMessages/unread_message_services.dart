import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';
import 'package:flutter_frontend/model/UnreadMsg.dart';

part 'unread_message_services.g.dart';

@RestApi(baseUrl: 'https://cmmteam3-backend-api.onrender.com/allunread')
abstract class UnreadMessageService {
  factory UnreadMessageService(Dio dio) => _UnreadMessageService(dio);

  @GET('')
  Future<UnreadMsg> getAllUnreadMsg(
      @Query('user_id') int userId, @Query('workspace_id') int workspaceId, @Header('Authorization') String token);
}
