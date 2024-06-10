
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/services/mChannelService/m_channel_service.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:dio/dio.dart';

class MChannelServices {
  final _apiService = MChannelService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  Future<void> createChannel(String channelName, int status) async {
    try {
      var token = await AuthController().getToken();
      int userId = SessionStore.sessionData!.currentUser!.id!.toInt();
      int workSpaceId = SessionStore.sessionData!.mWorkspace!.id!.toInt();

      Map<String, dynamic> requestBody = {
        "m_channel": {
          "user_id": userId,
          "channel_status": status,
          "channel_name": channelName,
          "m_workspace_id": workSpaceId
        }
      };
      await _apiService.createMChannel(requestBody, token!);
    } catch (e) {
      
      rethrow;
    }
  }

  Future<void> deleteChannel(int channelID) async {
    try {
      var token = await AuthController().getToken();
      await _apiService.deleteChannel(channelID, token!);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> updateChannel(
      int channelId, bool channelStatus, String channelName) async {
    String currentUser = SessionStore.sessionData!.currentUser!.name.toString();
    int workSpaceId = SessionStore.sessionData!.mWorkspace!.id!.toInt();

    Map<String, dynamic>? requestBody = {
      "m_channel": {
        "channel_status": channelStatus,
        "channel_name": channelName,
        "m_workspace_id": workSpaceId,
        "user_id": currentUser
      }
    };
    try {
      var token = await AuthController().getToken();
      await _apiService.updateChannel(channelId, requestBody, token!);
      return 'Channel has Been Update';
    } catch (e) {
     
      rethrow;
    }
  }

  Future<void> channelJoin(int userID, int channelId) async {
    var token = await AuthController().getToken();
    try {
      _apiService.joinChannel(userID, channelId, token!);
    } catch (e) {
      rethrow;
    }
  }
}
