import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/services/userservice/create_changepassword/login_change_service.dart';

class AuthController {
  Future<int> loginUser(
      String name, String password, String workspaceName, BuildContext context) async {
    
      final response = await http.post(
          Uri.parse('https://cmmteam3-backend-api.onrender.com/login'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: jsonEncode( {
            "user": {
              "name": name,
              "password": password,
              "workspace_name": workspaceName
            }
          }));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String token = data['token'];
        await saveToken(token.toString());
        return response.statusCode;
      } else {
        return response.statusCode;
      }
  }

  Future<void> saveToken(String token) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    await sharedPreferences.setString('token', token);
  }

  Future<void> removeToken() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    await sharedPreferences.remove('token');
  }

  Future<String?> getToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
     
      return null;
    }
  }

  Future<dynamic> createUser(
    String workspaceName,
    String channelName,
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    final _apiService = MuserService(Dio());

    try {
      await _apiService.createUser(({
        "m_user": {
          "remember_digest": workspaceName,
          "profile_image": channelName,
          "name": name,
          "email": email,
          "password": password,
          "password_confirmation": confirmPassword,
          "admin": "1"
        }
      }));
    } catch (e) {
      
      throw e;
    }
  }

  Future<void> changePassword(String password, String confirmPassword) async {
    int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
    final _apiService = MuserService(Dio());
    Map<String, dynamic> requestBody = {
      "m_user": {"password": password, "password_confirmation": confirmPassword}
    };
    try {
      var token = await AuthController().getToken();

      await _apiService.changePassword(currentUserId, requestBody, token!);
    } catch (e) {
      
      throw e;
    }
  }
}
