import 'package:dio/dio.dart';
import 'package:flutter_frontend/screens/groupMessage/Drawer/drawer.dart';
import 'package:flutter_frontend/services/confirmInvitation/confirm_invitation_service.dart';

class MemberInvitation {
  final _apiService = ConfirmInvitationService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  Future<String> memberInvitationConfirm(
      String password,
      String confirmPassword,
      String name,
      String email,
      String channelId,
      String workspaceName,
      int workspaceId) async {
    try {
      Map<String, dynamic> requestBody = {
        "m_user": {
          "remember_digest": workspaceName,
          "profile_image": channelId,
          "name": name,
          "email": email,
          "password": password,
          "password_confirmation": confirmPassword,
          "admin": false
        },
        "workspace_id": {"invite_workspaceid": workspaceId}
      };
      await _apiService.invitationConfirm(requestBody);

      return 'member confirmation successful';
    } catch (e) {
      throw e;
    }
  }
}
