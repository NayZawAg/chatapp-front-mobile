import 'dart:convert';
import 'package:flutter_frontend/const/mime_type.dart';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/userservice/profile_upload/upload_profile_service.dart';
import 'package:flutter_frontend/model/profileImage.dart';

class ProfileUploadApi {
  final _uploadService = UploadProfileService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  Future<ProfileImage> uploadProfileImage(PlatformFile? image) async {
    int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
    Map<String, dynamic> requestBody = {"user_id": currentUserId, "image": {}};

    try {
      if (image != null) {
        if (kIsWeb) {
          Uint8List imageBytes = image.bytes!;
          String base64Data = base64Encode(imageBytes);
          String? mimeType =
              lookupMimeType(image.name, headerBytes: imageBytes);
          requestBody["image"] = {"data": base64Data, "mime": mimeType};
        } else {
          String? imagePath = image.path;
          String mimeType = await MimeType.checkMimeType(imagePath!);
          String base64String = await MimeType.changeToBase64(imagePath);
          requestBody["image"] = {"data": base64String, "mime": mimeType};
        }
      }
      var token = await AuthController().getToken();
      var response = await _uploadService.uploadProfile(requestBody, token!);
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
