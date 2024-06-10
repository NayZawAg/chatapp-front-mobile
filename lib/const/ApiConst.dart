
import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConst {
  static getBaseUrl() {
  if (kIsWeb) {
    // Running on web
    return 'http://127.0.0.1:8000';
  } else if(Platform.isAndroid){
    // Running on mobile
    print("android");
    return 'http://192.168.2.24:8000';
  }else{
    return 'http://10.0.2.2:8000'; }
}
}
