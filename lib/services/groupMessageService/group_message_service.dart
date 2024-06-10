import 'dart:async';
import 'dart:convert';
import 'package:flutter_frontend/model/groupMessage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

Future<groupMessageData> fetchAlbum(int id) async {
  String? token = await getToken();
  // bool? isLoggedIn = await getLogin();
  if (token == null) {
    throw Exception('Token not available');
  }
  final response = await http.get(
    Uri.parse('https://cmmteam3-backend-api.onrender.com/m_channels/$id'),
    headers: <String, String>{
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    Map<String, dynamic> data = jsonDecode(response.body);
    groupMessageData groups = groupMessageData.fromJson(data);

    return groups;
  } else {
    throw Exception('Failed to load userdata');
  }
}

Future<void> sendGroupMessageData(String groupMessage, int channelID) async {
  String? token = await getToken();
  if (token == null) {
    throw Exception('Token not available');
  }

  final response = await http.post(
    Uri.parse('https://cmmteam3-backend-api.onrender.com/groupmsg'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({"s_channel_id": channelID, "message": groupMessage}),
  );
 
  if (response.statusCode == 200) {
   
  } else {
   
  }
}

Future<void> getMessageStar(int groupMessageID, int channelID) async {
  String? token = await getToken();
  if (token == null) {
    throw Exception('Token not available');
  }
  final response = await http.get(
    Uri.parse(
        'https://cmmteam3-backend-api.onrender.com/groupstar?id=$groupMessageID&s_channel_id=$channelID'),
    headers: <String, String>{
      'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
   
  } else {
    
  }
}

Future<void> deleteGroupStarMessage(int groupMessageID, int channelID) async {
  String? token = await getToken();
  if (token == null) {
    throw Exception('Token not available');
  }
  final response = await http.get(
    Uri.parse(
        'https://cmmteam3-backend-api.onrender.com/groupunstar?id=$groupMessageID&s_channel_id=$channelID'),
    headers: <String, String>{
      'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
   
  } else {
   
  }
}

Future<void> deleteGroupMessage(int groupMessageID, int channelID) async {
  String? token = await getToken();
  if (token == null) {
    throw Exception('Token not available');
  }
  final response = await http.get(
    Uri.parse(
        'https://cmmteam3-backend-api.onrender.com/delete_groupmsg?id=$groupMessageID&s_channel_id=$channelID'),
    headers: <String, String>{
      'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
    
  } else {
    
  }
}

Future<void> deleteMember(int id, int channelID) async {
  String? token = await getToken();
  if (token == null) {
    throw Exception('Token not available');
  }
  final response = await http.get(
      Uri.parse(
          'https://cmmteam3-backend-api.onrender.com/channeluserdestroy?id=$id&channel_id=$channelID'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      });
  if (response.statusCode == 200) {
    
  } else {
    
  }
}

Future<void> deleteChannel(int channelID) async {
  String? token = await getToken();
  if (token == null) {
    throw Exception('Token not available');
  }
  final response = await http.delete(
      Uri.parse(
          'https://cmmteam3-backend-api.onrender.com/m_channels/$channelID'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      });
  if (response.statusCode == 200) {
    
  } else {
   
  }
}

Future<bool> updateChannel(
    int id, bool channelStatus, String channelName, int workspaceId) async {
  String? token = await getToken();
  try {
    if (token == null) {
      throw Exception('Token not available');
    }
    final response = await http.post(
        Uri.parse('https://cmmteam3-backend-api.onrender.com/channelupdate?id=$id'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(
          {
            "m_channel":{
              "channel_status": channelStatus,
              "channel_name": channelName,
              "m_workspace_id": workspaceId
        }
          }
        ));
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
