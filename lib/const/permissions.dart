import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionClass {
  TargetPlatform? platform;

 Future<bool> checkPermission() async {
    if (platform == TargetPlatform.android) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }
}