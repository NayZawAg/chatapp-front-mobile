import 'dart:async';
import 'dart:convert';

import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/services/directMessage/directMessage/direct_meessages.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class DirectMessageService {
  final _apiSerive = ApiService(Dio(BaseOptions(headers: {'Content-Type': 'application/json', 'Accept': 'application/json'})));
  Future<void> sendDirectMessage(int receiverUserId, String message) async {
    int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
    Map<String, dynamic> requestBody = {
      "message": message,
      "user_id": currentUserId,
      "s_user_id": receiverUserId
    };

    try {
      var token = await AuthController().getToken();
      await _apiSerive.sendMessage(requestBody, token!);
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendDirectMessageThread(
      int directMsgId, int receiveUserId, String message) async {
    String url = "http://192.168.2.24:8001/directthreadmsg";
    int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
    Map<String, dynamic> requestBody = {
      "s_direct_message_id": directMsgId,
      "s_user_id": receiveUserId,
      "message": message,
      "user_id": currentUserId
    };
    try {
      var token = await AuthController().getToken();
      var response = await http.post(Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode(requestBody));
      if (response.statusCode == 200) {
        
      } else {
        
      }
    } catch (e) {
    }
  }

  Future<void> directStarMsg(int receiveUserId, int messageId) async {
    int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();

    try {
      var token = await AuthController().getToken();
      await _apiSerive.directStarMsg(
          receiveUserId, messageId, currentUserId, token!);
    } catch (e) {
      throw e;
    }
  }

  Future<void> directUnStarMsg(int starId) async {
    try {
      var token = await AuthController().getToken();
      await _apiSerive.directUnStarMsg(starId, token!);
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteMsg(int msgId) async {
    try {
      var token = await AuthController().getToken();
      await _apiSerive.deleteMessage(msgId, token!);
    } catch (e) {}
  }
}
