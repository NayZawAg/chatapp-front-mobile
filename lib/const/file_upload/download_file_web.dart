import 'dart:io';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class DownloadFile {
  static Future<void> downloadFile(
      String fileUrl, String filename, BuildContext context) async {
    try {
      final PermissionClass permission = PermissionClass();
      bool permissionGranted = await permission.checkPermission();
      if (permissionGranted) {
        Directory? dir = await getExternalStorageDirectory();
        String fullPath = '${dir?.path}/$filename';
        await Dio().download(fileUrl, fullPath);
        if (fileUrl.endsWith('.png') ||
            fileUrl.endsWith('.jpg') ||
            fileUrl.endsWith('.jpeg') ||
            fileUrl.endsWith('.gif') ||
            fileUrl.endsWith('.bmp')) {
          await GallerySaver.saveImage(fileUrl, albumName: 'MiMo')
              .then((success) {
            if (success != null && success) {
              fullPath = 'saved to gallery';
            }
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            "Download Completed: $fullPath",
            style: const TextStyle(fontSize: 14),
          )),
        );
      }
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download Failed: $e")),
      );
    }
  }
}
