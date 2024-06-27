import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/const/file_upload/change_mime.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/groupMessage.dart';
import 'package:flutter_frontend/services/groupMessageService/gropMessage/groupMessage_Services.dart';
import 'package:flutter_frontend/services/groupThreadApi/retrofit/groupThread_services.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupMessageServiceImpl {
  final _apiService = GroupMessageServices(Dio());
  final _apiServices = GroupThreadServices(Dio());

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<GroupMessgeModel> fetchAlbum(int id) async {
    String? token = await getToken();

    if (token == null) {
      throw Exception('Token not available');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/m_channels/$id'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      GroupMessgeModel groups = GroupMessgeModel.fromJson(data);

      return groups;
    } else {
      throw Exception('Failed to load userdata');
    }
  }

  Future<void> sendGroupMessageData(String groupMessage, int channelID,
      List<String> mentionName, List<PlatformFile>? files) async {
    var token = await getToken();

    Map<String, dynamic> requestBody = {
      "s_channel_id": channelID,
      "message": groupMessage,
      "mention_name": mentionName,
      "files": []
    };
    try {
      if (files != null) {
        for (PlatformFile file in files) {
          if (kIsWeb) {
            Uint8List fileBytes = file.bytes!;
            String fileName = file.name;
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
      await _apiService.sendGroupMsgData(requestBody, token!);
      print("This is from request body");
      print(requestBody);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> getMessageStar(int groupMessageID, int channelID) async {
    String? token = await getToken();
    if (token == null) {
      throw Exception('Token not available');
    }
    final response = await http.get(
      Uri.parse(
          '$baseUrl/groupstar?id=$groupMessageID&s_channel_id=$channelID'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
    } else {}
  }

  Future<void> sendGroupThreadData(String groupMessage, int channelID,
      int messageID, List<String> mentionName, List<PlatformFile>? files) async {
    final token = await getToken();
    Map<String, dynamic> requestBody = {
      "s_group_message_id": messageID,
      "s_channel_id": channelID,
      "message": groupMessage,
      "mention_name": mentionName,
      "files": []
    };
    try {
      if (files != null) {
        for (PlatformFile file in files) {
          if (kIsWeb) {
            Uint8List fileBytes = file.bytes!;
            String fileName = file.name;
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
      await _apiServices.sendGroupThreadData(requestBody, token!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteGroupStarMessage(int groupMessageID, int channelID) async {
    String? token = await getToken();
    if (token == null) {
      throw Exception('Token not available');
    }
    final response = await http.get(
      Uri.parse(
          '$baseUrl/groupunstar?id=$groupMessageID&s_channel_id=$channelID'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
    } else {}
  }

  Future<void> deleteGroupMessage(int groupMessageID, int channelID) async {
    String? token = await getToken();
    if (token == null) {
      throw Exception('Token not available');
    }
    final response = await http.get(
      Uri.parse(
          '$baseUrl/delete_groupmsg?id=$groupMessageID&s_channel_id=$channelID'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
    } else {}
  }

  Future<void> deleteMember(int id, int channelID) async {
    String? token = await getToken();
    if (token == null) {
      throw Exception('Token not available');
    }
    final response = await http.get(
        Uri.parse('$baseUrl/channeluserdestroy?id=$id&channel_id=$channelID'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        });
    if (response.statusCode == 200) {
    } else {}
  }

  Future<void> deleteChannel(int channelID) async {
    String? token = await getToken();
    if (token == null) {
      throw Exception('Token not available');
    }
    final response = await http.delete(
        Uri.parse('$baseUrl/m_channels/$channelID'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        });
    if (response.statusCode == 200) {
    } else {}
  }

  Future<bool> updateChannel(
      int id, bool channelStatus, String channelName, int workspaceId) async {
    String? token = await getToken();
    try {
      if (token == null) {
        throw Exception('Token not available');
      }
      final response =
          await http.post(Uri.parse('$baseUrl/channelupdate?id=$id'),
              headers: <String, String>{
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                "m_channel": {
                  "channel_status": channelStatus,
                  "channel_name": channelName,
                  "m_workspace_id": workspaceId
                }
              }));
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 422) {
        return false;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }
}
