import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';
import 'package:flutter_frontend/model/MentionLists.dart';

part 'mention_list.service.g.dart';

@RestApi(baseUrl: 'https://cmmteam3-backend-api.onrender.com/mentionlists')
abstract class MentionListService {
  factory MentionListService(Dio dio) => _MentionListService(dio);

  @GET('')
  Future<MentionLists> getAllMentionList(
      @Query('user_id') int userId, @Header('Authorization') String token);
}
