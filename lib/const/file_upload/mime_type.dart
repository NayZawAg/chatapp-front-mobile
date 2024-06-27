import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:mime/mime.dart';

class MimeType {

  static Future<String> checkMimeType({String? filePath, Uint8List? fileBytes}) async {
    if (filePath != null) {
      // For mobile platforms
      String? mimetype = lookupMimeType(filePath);
      return mimetype!;
    } else if (fileBytes != null) {
      // For web platforms
      String? mimetype = lookupMimeType('', headerBytes: fileBytes);
      return mimetype!;
    } else {
      throw ArgumentError('Either filePath or fileBytes must be provided.');
    }
  }

  static Future<String> changeToBase64({String? imagePath, Uint8List? imageBytes}) async {
    if (imagePath != null) {
      // For mobile platforms
      File imageFile = File(imagePath);
      Uint8List bytes = await imageFile.readAsBytes();
      String base64String = base64Encode(bytes);
      return base64String;
    } else if (imageBytes != null) {
      // For web platforms
      String base64String = base64Encode(imageBytes);
      return base64String;
    } else {
      throw ArgumentError('Either imagePath or imageBytes must be provided.');
    }
  }
}