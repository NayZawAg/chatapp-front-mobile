import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:mime/mime.dart';
class MimeType{
  static Future<String>  checkMimeType(String filepath) async {
    String? mimetype =  lookupMimeType(filepath);
    return  mimetype!;
  }
  static Future<String> changeToBase64(String imagePath) async {
    File imageFile = File(imagePath);
    Uint8List bytes =  await imageFile.readAsBytes();
    String base64String =   base64Encode(bytes);
    return base64String;
  }
}