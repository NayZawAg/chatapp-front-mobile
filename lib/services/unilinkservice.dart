// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:uni_links/uni_links.dart';
// import 'package:flutter_frontend/services/contextutility.dart';
// import 'package:flutter_frontend/screens/Welcome/components/welcome_image.dart';
// import 'package:flutter_frontend/screens/confirmInvitation/member_confirm_invitation.dart';





// class UniServices{
//   static String _path = '';
//   static String get path => _path;
//   static bool get hasPath => _path.isNotEmpty;
//   static String? receivedPath;
//   static String? workspaceId;
//   static String? channelId;
//   static String? email;

//   static void reset() => _path = '';

//   static init() async {
//     try{
//       final Uri? uri = await getInitialUri();
//       uniHandler(uri);
//     }on PlatformException{
//       log("Failed to receive the path!");
//     }on FormatException{
//       log("Wrong format path received!");
//     }

//     uriLinkStream.listen((Uri? uri) async {
//       uniHandler(uri);
//     },onError: (error){
//       log("OnUriLink Error: $error");
//     });
//   }

//   // void uniHandler(Uri uri) {
//   // if (uri == null || uri.queryParameters.isEmpty) return;

//   // String? receivedPath = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
//   // String workspaceId = uri.queryParameters['workspaceid'] ?? '';
//   // String channelId = uri.queryParameters['channelid'] ?? '';
//   // String email = uri.queryParameters['email'] ?? '';

//   // int intWorkspaceId = int.tryParse(workspaceId) ?? 0;
//   // int intChannelId = int.tryParse(channelId) ?? 0;

//   // if (receivedPath == "confirminvitation") {
//   //   Navigator.push(MaterialApp().context, MaterialPageRoute(builder: (_) => ConfirmPage(workspaceId: intWorkspaceId, channelId: intChannelId, email: email)));
//   // } else {
//   //   Navigator.push(MaterialApp().context, MaterialPageRoute(builder: (_) => WelcomeImage()));
//   // }


//   static uniHandler(Uri? uri){
//     if(uri == null || uri.queryParameters.isEmpty) return;
//     Map<String,String> param = uri.queryParameters;
//     workspaceId = param['workspaceId'] ?? '';
//     channelId = param['channelId'] ?? '';
//     email = param['email'] ?? '';

//     var intWorkspaceId = int.parse(workspaceId!);

//     var intChannelId = int.parse(channelId!);
//     if(receivedPath == "confirminvitation"){
//       Navigator.push(ContextUtility.context!,MaterialPageRoute(builder: (_) => ConfirmPage(workspaceId: intWorkspaceId,channelId: intChannelId,email: email,)));
//     }else{
//       Navigator.push(ContextUtility.context!,MaterialPageRoute(builder: (_) => WelcomeImage()));
//     }
//   }
// }