import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class PickFiles {
  Future<void> _prepareSaveDir(
      String localpath, TargetPlatform platform) async {
    localpath = (await _findLocalPath(platform))!;
    print(localpath);
    final saveDir = Directory(localpath);
    bool hasExisted = await saveDir.exists();
    if (!hasExisted) {
      await saveDir.create();
    }
  }

  Future<String?> _findLocalPath(TargetPlatform platform) async {
    if (platform == TargetPlatform.android) {
      return "/sdcard/download/";
    } else {
      var directory = await getApplicationDocumentsDirectory();
      return '${directory.path}${Platform.pathSeparator}Download';
    }
  }
}
