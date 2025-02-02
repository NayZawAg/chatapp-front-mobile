import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/const/file_upload/change_mime.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/services/directMessage/directMessage/direct_meessages.dart';
import 'package:flutter_frontend/services/directMessage/directMessageThread/direct_message_thread.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

class DirectMessageService {
  final _apiSerive = ApiService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  final thread_service = DirectMsgThreadService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  Future<void> sendDirectMessage(
      int receiverUserId, String message, List<PlatformFile>? files) async {
    int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
    Map<String, dynamic> requestBody = {
      "message": message,
      "user_id": currentUserId,
      "s_user_id": receiverUserId,
      "files": []
    };
    try {
      if (files != null) {
        for (PlatformFile file in files) {
          if (kIsWeb) {
            Uint8List fileBytes = file.bytes!;
            String? fileName = file.name;
            String base64Data = base64Encode(fileBytes);
            String? mimeType =
                lookupMimeType(file.name, headerBytes: fileBytes);
            requestBody["files"].add(
                {"data": base64Data, "mime": mimeType, "file_name": fileName});
          } else {
            String? filePath = file.path;
            String? fileName = file.name;
            String mimeType = await MimeType.checkMimeType(filePath!);
            String base64String = await MimeType.changeToBase64(filePath);
            requestBody["files"].add({
              "data": base64String,
              "mime": mimeType,
              "file_name": fileName
            });
          }
        }
      }
      var token = await AuthController().getToken();
      await _apiSerive.sendMessage(requestBody, token!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendDirectMessageThread(int directMsgId, int receiveUserId,
      String message, List<PlatformFile>? files) async {
    String url = "http://localhost:3000/directthreadmsg";
    int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
    Map<String, dynamic> requestBody = {
      "s_direct_message_id": directMsgId,
      "s_user_id": receiveUserId,
      "message": message,
      "user_id": currentUserId,
      "files": []
    };
    try {
      if (files != null) {
        for (PlatformFile file in files) {
          if (kIsWeb) {
            Uint8List fileBytes = file.bytes!;
            String? fileName = file.name;
            String base64Data = base64Encode(fileBytes);
            String? mimeType =
                lookupMimeType(file.name, headerBytes: fileBytes);
            requestBody["files"].add(
                {"data": base64Data, "mime": mimeType, "file_name": fileName});
          } else {
            String? filePath = file.path;
            String? fileName = file.name;
            String mimeType = await MimeType.checkMimeType(filePath!);
            String base64String = await MimeType.changeToBase64(filePath);
            requestBody["files"].add({
              "data": base64String,
              "mime": mimeType,
              "file_name": fileName
            });
          }
        }
      }
      var token = await AuthController().getToken();
      await thread_service.sentThread(requestBody, token!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> directReactMsg(
      String emoji, int msgId, int selectedUserId, int userId) async {
    try {
      var token = await AuthController().getToken();
      Map<String, dynamic> requestBody = {
        "message_id": msgId,
        "s_user_id": selectedUserId,
        "emoji": emoji,
        "user_id": userId
      };
      await _apiSerive.directReactMsg(requestBody, token!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> editDirectMessge(String message, int msgId) async {
    try {
      var token = await AuthController().getToken();
      Map<String, dynamic> requestBody = {'id': msgId, 'message': message};
      await _apiSerive.editdirectMessage(requestBody, token!);
    } catch (e) {
      rethrow;
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
    } catch (e) {
      rethrow;
    }
  }
}
