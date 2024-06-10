import 'package:flutter/material.dart';
import 'package:flutter_frontend/model/direct_message.dart';
import 'package:flutter_frontend/model/user_management.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/userservice/usermanagement/user_management_service.dart';
import 'package:dio/dio.dart';

class DirectMessageProvider extends ChangeNotifier {
  bool isLoading = false;
  DirectMessages? directMessages;
  final UserManagementService _userManagementService = UserManagementService(
      Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  UserManagement? userManagement;
  Locale? _locale;

  Locale get locale => _locale!;

  Future getAllUsers() async {
    isLoading = true;
    notifyListeners();
    var token = await AuthController().getToken();
    final response = await _userManagementService.getAllUser(token!);
    userManagement = response;
    isLoading = false;
    notifyListeners();
  }
}
