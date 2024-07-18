import 'dart:convert';

// import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/group_thread_list.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:http/http.dart' as http;

import 'retrofit/groupThread_services.dart';

class GpThreadMsg {
  final _apiService = GroupThreadServices(Dio());

  Future<GroupThreadMessage> fetchGpThread(int id, int channelID) async {
    var token = await AuthController().getToken();
    // bool? isLoggedIn = await getLogin();
    if (token == null) {
      throw Exception('Token not available');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/t_group_messages/${id}?s_channel_id=$channelID'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      GroupThreadMessage thread = GroupThreadMessage.fromJson(data);

      return thread;
    } else {
      throw Exception('Failed to load userdata');
    }
  }

  Future<void> sendGroupThreadData(String groupMessage, int channelID,
      int messageID, String mentionName) async {
    var token = await AuthController().getToken();
    // int id = SessionStore.sessionData!.currentUser!.id!.toInt();
    final response = await http.post(
      Uri.parse('$baseUrl/groupthreadmsg'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "s_group_message_id": messageID,
        "s_channel_id": channelID,
        "message": groupMessage,
        "memtion_name": mentionName
      }),
    );

    if (response.statusCode == 200) {
    } else {}
  }

  Future<void> deleteGpThread(
      int threadID, int channelID, int groupMesssageID) async {
    var token = await AuthController().getToken();
    final url =
        '$baseUrl/delete_groupthread?id=${threadID}&s_channel_id=${channelID}&s_group_message_id=${groupMesssageID}';
    final Response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
    if (Response.statusCode == 200) {
    } else {}
  }

  Future<void> editGroupThreadMessage(
      String message, int msgId, List<String> mentionnames) async {
    var token = await AuthController().getToken();
    Map<String, dynamic> requestBody = {
      'id': msgId,
      'message': message,
      'mention_name': mentionnames
    };
    await _apiService.editGroupThreadMessage(requestBody, token!);
  }

  Future<void> groupThreadReaction(
      {required int threadId,
      required String emoji,
      required String emojiName,
      required int selectedGpMsgId,
      required int sChannelId}) async {
    var token = await AuthController().getToken();
    Map<String, dynamic> requestBody = {
      "thread_id": threadId,
      "s_channel_id": sChannelId,
      "emoji": emoji,
      "emoji_name": emojiName,
      "s_group_message_id": selectedGpMsgId
    };
    await _apiService.groupThreadReaction(requestBody, token!);
  }

  Future<void> sendStarThread(
      int threadID, int channelID, int groupMesssageID) async {
    var token = await AuthController().getToken();
    final url =
        '$baseUrl/groupstarthread?id=${threadID}&s_channel_id=${channelID}&s_group_message_id=${groupMesssageID}';
    final Response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
    if (Response.statusCode == 200) {
    } else {}
  }

  Future<void> unStarThread(
      int threadID, int channelID, int groupMesssageID) async {
    var token = await AuthController().getToken();
    final url =
        '$baseUrl/groupunstarthread?id=${threadID}&s_channel_id=${channelID}&s_group_message_id=${groupMesssageID}';
    final Response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
    if (Response.statusCode == 200) {
    } else {}
  }
}
