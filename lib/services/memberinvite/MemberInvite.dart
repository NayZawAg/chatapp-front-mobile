import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/memberinvite/member_invite.dart';
import 'package:dio/dio.dart';

class MemberInviteServices{
  
  Future<void> memberInvite(String email, int channelID) async {
     var _apiService = MemberInviteService(Dio(BaseOptions(headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'})));
    int workSpace = SessionStore.sessionData!.mWorkspace!.id!.toInt();
    try {
      var token = await AuthController().getToken();

      Map<String, dynamic> requestBody = {
        "m_invite": {
          "email": email,
          "channel_id": channelID,
          "workspace_id": workSpace
        }
      };
      await _apiService.memberinvitation(token!, requestBody);
     
    
    } catch (e) {
      
      throw e;
    }
  }
}
