import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_frontend/screens/Welcome/welcome_screen.dart';
import 'package:flutter_frontend/screens/confirmInvitation/member_confirm_invitation.dart';
import 'package:flutter_frontend/services/directMessage/provider/direct_message_provider.dart';
// import 'package:flutter_frontend/services/contextutility.dart';
// import 'package:flutter_frontend/services/unilinkservice.dart';
// import 'package:flutter_web_plugins/flutter_web_plugins.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  setPathUrlStrategy();
  runApp(const MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Trust all certificates (for testing purposes only)
        return true;
      };
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DirectMessageProvider()),
      ],
      child: MaterialApp.router(
        routerConfig: _route,
        builder: (_, child) => Portal(child: child!),
        debugShowCheckedModeBanner: false,
        title: 'MiMo',
        theme: ThemeData(
          primaryColor: kPrimaryColor,
          scaffoldBackgroundColor: Colors.white,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              foregroundColor: Colors.white,
              backgroundColor: kPrimaryColor,
              shape: const StadiumBorder(),
              maximumSize: const Size(double.infinity, 56),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: kPrimaryLightColor,
            iconColor: kPrimaryColor,
            prefixIconColor: kPrimaryColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: defaultPadding,
              vertical: defaultPadding,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              borderSide: BorderSide.none,
            ),
  
          )), ));
        
  }
}
final GoRouter _route = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, state) => WelcomeScreen()),
    GoRoute(
        path: '/confirminvitation',
        builder: (context, state) {
          final channel_id = int.tryParse(state.queryParams['channelid'] ?? '');
          final email = state.queryParams['email'];
          final workspace_id =
              int.tryParse(state.queryParams['workspaceid'] ?? '');
          return ConfirmPage(
            channelId: channel_id ?? 0,
            email: email ?? '',
            workspaceId: workspace_id ?? 0,
          );
        })
  ]);