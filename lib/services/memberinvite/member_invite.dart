import 'package:dio/dio.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:retrofit/http.dart';

part 'member_invite.g.dart';

@RestApi(baseUrl: '$baseUrl/memberinvite')
abstract class MemberInviteService {
  factory MemberInviteService(Dio dio) => _MemberInviteService(dio);

  @POST('')
  Future<void> memberinvitation(@Header('Authorization') String token,
      @Body() Map<String, dynamic> requestBody);
}
