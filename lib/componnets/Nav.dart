import 'dart:async';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/dataInsert/mention_list.dart';
import 'package:flutter_frontend/model/dataInsert/thread_lists.dart';
import 'package:flutter_frontend/model/dataInsert/unread_list.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/screens/Mention/mention_body.dart';
import 'package:flutter_frontend/screens/Star/star_body.dart';
import 'package:flutter_frontend/screens/home/workspacehome.dart';
import 'package:flutter_frontend/screens/threadMessage/thread_message.dart';
import 'package:flutter_frontend/screens/unreadMessage/unread_msg.dart';
import 'package:flutter_frontend/services/mentionlistsService/mention_list.service.dart';
import 'package:flutter_frontend/services/starlistsService/star_list.service.dart';
import 'package:flutter_frontend/services/threadMessages/thread_message_service.dart';
import 'package:flutter_frontend/services/unreadMessages/unread_message_services.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/model/dataInsert/star_list.dart';
import 'package:dio/dio.dart';

class Nav extends StatefulWidget {
  const Nav({Key? key});

  @override
  State<Nav> createState() => _NavState();
}

class _NavState extends State<Nav> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  final List<bool> _dataFetched = [false, false, false, false, false];
  static const List<Widget> _page = [
    WorkHome(),
    MentionBody(),
    StarBody(),
    ThreadList(),
    unreadMessage()
  ];

  final List<Completer<void>> _completers = List.filled(5, Completer<void>());

  Future<void> _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (!_dataFetched[index]) {
      if (!_completers[index].isCompleted) _completers[index].complete();

      _completers[index] = Completer<void>();

      setState(() {
        _isLoading = true;
      });

      await fetchDataForIndex(index);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> fetchDataForIndex(int index) async {
    switch (index) {
      case 1:
        await getAllMentionMessages();
        break;
      case 2:
        await getStarLists();
        break;
      case 3:
        await getThreadMessages();
        break;
      case 4:
        await getAllUnreadMessages();
        break;
    }
    _dataFetched[index] = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const ProgressionBar(
              imageName: "list_sending.json", height: 200, size: 200)
          : _page[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        height: 50,
        backgroundColor: const Color.fromARGB(255, 246, 255, 255),
        color: navColor,
        animationDuration: const Duration(milliseconds: 300),
        index: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          Icon(
            Icons.home,
            color: Colors.white,
          ),
          Icon(
            Icons.alternate_email,
            color: Colors.white,
          ),
          Icon(
            Icons.star,
            color: Colors.white,
          ),
          Icon(
            Icons.message_sharp,
            color: Colors.white,
          ),
          Icon(
            Icons.mail,
            color: Colors.white,
          )
        ],
      ),
    );
  
  }

  getStarLists() async {
    int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();

    try {
      var token = await AuthController().getToken();
      var starListStore = await StarListsService(Dio(BaseOptions(headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }))).getAllStarList(currentUserId, token!);
      StarListStore.starList = starListStore;
    } catch (e) {
      rethrow;
    }
  }

  getThreadMessages() async {
    int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
    try {
      var token = await AuthController().getToken();
      var threadListStore = await ThreadService(Dio(BaseOptions(headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }))).getAllThreads(currentUserId, token!);
      ThreadStore.thread = threadListStore;
    } catch (e) {
      rethrow;
    }
  }

  getAllMentionMessages() async {
    int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
    try {
      var token = await AuthController().getToken();
      var mentionList = await MentionListService(Dio(BaseOptions(headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }))).getAllMentionList(currentUserId, token!);
      MentionStore.mentionList = mentionList;
    } catch (e) {
      rethrow;
    }
  }

  getAllUnreadMessages() async {
    int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
    try {
      var token = await AuthController().getToken();
      var unreadListStore = await UnreadMessageService(Dio(BaseOptions(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }))).getAllUnreadMsg(currentUserId, token!);
      UnreadStore.unreadMsg = unreadListStore;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _completers.forEach((Completer<void> completer) {
      if (!completer.isCompleted) completer.complete();
    });
    super.dispose();
  }
}
