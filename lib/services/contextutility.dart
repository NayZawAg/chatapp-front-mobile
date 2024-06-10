import 'package:flutter/material.dart';

class ContextUtility{
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>(); 
  static GlobalKey<NavigatorState> get navigatorkey => _navigatorKey;

  static NavigatorState? get  navigator => navigatorkey.currentState;

  static BuildContext? get context => navigator?.overlay?.context;
}