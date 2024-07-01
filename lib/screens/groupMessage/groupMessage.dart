import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/const/build_fiile.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:flutter_frontend/constants.dart';

import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/screens/groupMessage/Drawer/drawer.dart';
import 'package:flutter_frontend/services/groupMessageService/group_message_service.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/groupMessage.dart';

import 'package:flutter_frontend/screens/groupMessage/groupThread.dart';
import 'package:flutter_frontend/services/groupMessageService/gropMessage/groupMessage_Services.dart';
import 'package:intl/intl.dart';
// ignore_for_file: prefer_const_constructors, must_be_immutable

// ignore: depend_on_referenced_packages

class GroupMessage extends StatefulWidget {
  final channelID, channelName, workspace_id, memberName;
  final channelStatus;
  final member;
  GroupMessage(
      {super.key,
      this.channelID,
      this.channelStatus,
      this.channelName,
      this.member,
      this.workspace_id,
      this.memberName});

  @override
  State<GroupMessage> createState() => _GroupMessage();
}

class _GroupMessage extends State<GroupMessage> with RouteAware {
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  final groupMessageService = GroupMessageServices(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  late ScrollController _scrollController;
  RetrieveGroupMessage? retrieveGroupMessage;
  Retrievehome? retrievehome;
  GroupMessgeModel? groupdata;
  String currentUserName =
      SessionStore.sessionData!.currentUser!.name.toString();
  int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();

  List<int>? tGroupStarMsgids = [];

  List<TGroupMessages>? tGroupMessages = [];

  WebSocketChannel? _channel;
  String? groupMessageName;
  bool isloading = false;
  bool isButtom = false;

  bool isLoading = false;
  bool isSelected = false;
  bool isStarred = false;
  int? _selectedMessageIndex;
  int? selectUserId;
  bool hasFileToSEnd = false;
  List<PlatformFile> files = [];
  late String localpath;
  late bool permissionReady;
  TargetPlatform? platform;
  final PermissionClass permissions = PermissionClass();
  String? fileText;

  BuildSingleFile singleFile = BuildSingleFile();
  BuildMulitFile mulitFile = BuildMulitFile();
  final _apiSerive = GroupMessageServiceImpl();
  late List<Map<String, Object?>> mention;

  @override
  void initState() {
    super.initState();
    loadMessage();
    connectWebSocket();
    if (kIsWeb) {
      return;
    } else if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }
    _scrollController = ScrollController();

    _scrollToBottom();
  }

  @override
  void dispose() {
    super.dispose();
    _channel!.sink.close();
    _scrollController.dispose();
  }

  void connectWebSocket() {
    var url =
        'ws://$wsUrl/cable?channel_id=${widget.workspace_id}&user_id=$currentUserId';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'GroupChannel'}),
    });

    _channel!.sink.add(subscriptionMessage);

    _channel!.stream.listen(
      (message) {
        try {
          var parsedMessage = jsonDecode(message) as Map<String, dynamic>;

          if (parsedMessage.containsKey('type') &&
              parsedMessage['type'] == 'ping') {
            return;
          }

          if (parsedMessage.containsKey('message')) {
            var messageContent = parsedMessage['message'];

            // Handling chat message
            if (messageContent != null &&
                messageContent.containsKey('message')) {
              var msg = messageContent['message'];

              if (msg != null &&
                  msg.containsKey('groupmsg') &&
                  msg['m_channel_id'] == widget.channelID) {
                var groupMessage = msg['groupmsg'];
                int id = msg['id'];
                var date = msg['created_at'];
                int mUserId = msg['m_user_id'];
                List<dynamic> fileUrls = [];
                String senduser = messageContent['sender_name'];

                if (messageContent.containsKey('files')) {
                  var files = messageContent['files'];
                  if (files != null) {
                    fileUrls = files.map((file) => file['file']).toList();
                  }
                }

                setState(() {
                  tGroupMessages!.add(TGroupMessages(
                      createdAt: date,
                      fileUrls: fileUrls,
                      groupmsg: groupMessage,
                      id: id,
                      sendUserId: mUserId,
                      name: senduser));
                });
              } else {}
            } else if (messageContent.containsKey('messaged_star') &&
                messageContent['m_channel_id'] == widget.channelID) {
              var messageStarData = messageContent['messaged_star'];

              if (messageStarData != null &&
                  messageStarData['userid'] == currentUserId) {
                int groupmsgid = messageStarData['groupmsgid'];

                setState(() {
                  tGroupStarMsgids!.add(groupmsgid);
                });
              } else {}
            } else if (messageContent.containsKey('unstared_message') &&
                messageContent['m_channel_id'] == widget.channelID) {
              var unstaredMsg = messageContent['unstared_message'];

              if (unstaredMsg != null &&
                  unstaredMsg['userid'] == currentUserId) {
                int unstaredMsgId = unstaredMsg['groupmsgid'];
                setState(() {
                  tGroupStarMsgids!.removeWhere(
                    (element) => element == unstaredMsgId,
                  );
                });
              }
            } else {
              var deletemsg = messageContent['delete_msg'];

              int id = deletemsg['id'];

              setState(() {
                tGroupMessages?.removeWhere((element) => element.id == id);
              });
            }
          } else {}
        } catch (e) {
          rethrow;
        }
      },
      onDone: () {
        _channel!.sink.close();
      },
      onError: (error) {},
    );
  }

  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() {
      files.addAll(result.files);
      hasFileToSEnd = true;
    });
  }

  void loadMessage() async {
    var token = await AuthController().getToken();
    GroupMessgeModel data =
        await groupMessageService.getAllGpMsg(widget.channelID, token!);

    setState(() {
      retrieveGroupMessage = data.retrieveGroupMessage;
      retrievehome = data.retrievehome;
      groupdata = data;
      tGroupStarMsgids = data.retrieveGroupMessage!.tGroupStarMsgids;
      tGroupMessages = data.retrieveGroupMessage!.tGroupMessages;
      isLoading = true;
    });
    mention = retrieveGroupMessage!.mChannelUsers!.map((e) {
      return {'display': e.name, 'name': e.name};
    }).toList();
  }

  void _scrollToBottom() {
    if (isButtom) return;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendGroupMessageData(
      String groupMessage, int channelId, List<String> mentionName) async {
    if (key.currentState!.controller!.text.isNotEmpty || files.isNotEmpty) {
      try {
        await _apiSerive.sendGroupMessageData(
            groupMessage, channelId, mentionName, files);
        files.clear();
      } catch (e) {
        rethrow;
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  String? channelName;
  int? memberCount;

  @override
  Widget build(BuildContext context) {
    return isLoading == false
        ? ProgressionBar(imageName: 'loading.json', height: 200, size: 200)
        : Scaffold(
            backgroundColor: kPriamrybackground,
            resizeToAvoidBottomInset: true,
            key: _scaffoldKey,
            drawer: Drawer(
              child: DrawerPage(
                  channelId: widget.channelID,
                  channelName: widget.channelName,
                  channelStatus: widget.channelStatus,
                  memberCount: memberCount,
                  memberName: widget.memberName,
                  member: retrieveGroupMessage!.mChannelUsers,
                  adminID: retrieveGroupMessage!.create_admin),
            ),
            appBar: AppBar(
              leading: IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => const Nav()));
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              backgroundColor: navColor,
              title: Row(
                children: [
                  Container(
                    child: widget.channelStatus
                        ? Icon(
                            Icons.tag,
                            color: Colors.white,
                          )
                        : Icon(
                            Icons.lock,
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      GestureDetector(
                          onTap: () {
                            _openDrawer();
                          },
                          child: Text(
                            widget.channelName,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )),
                    ],
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                    child: ListView.builder(
                  itemCount: retrieveGroupMessage!.tGroupMessages!.length,
                  itemBuilder: (context, index) {
                    var channelStar = tGroupMessages!;

                    List<dynamic>? files = [];
                    files = tGroupMessages![index].fileUrls;

                    List<int> tempStar = tGroupStarMsgids?.toList() ?? [];
                    bool isStared = tempStar.contains(channelStar[index].id);

                    String message = channelStar[index].groupmsg ?? "";
                    String sendername = tGroupMessages![index].name.toString();

                    int count = channelStar[index].count ?? 0;
                    String time = channelStar[index].createdAt.toString();
                    DateTime date = DateTime.parse(time).toLocal();

                    String created_at =
                        DateFormat('MMM d, yyyy hh:mm a').format(date);
                    bool isMessageFromCurrentUser =
                        currentUserName == channelStar[index].name;
                    int sendUserId = tGroupMessages![index].sendUserId!.toInt();

                    return SingleChildScrollView(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMessageIndex = channelStar[index].id;
                            isSelected = !isSelected;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isMessageFromCurrentUser)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (_selectedMessageIndex ==
                                            channelStar[index].id &&
                                        !isSelected)
                                      Align(
                                        child: Container(
                                          padding: const EdgeInsets.all(3.0),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                IconButton(
                                                  onPressed: () async {
                                                    if (_selectedMessageIndex !=
                                                        null) {
                                                      await _apiSerive
                                                          .deleteGroupMessage(
                                                              tGroupMessages![
                                                                      index]
                                                                  .id!,
                                                              widget.channelID);
                                                    }
                                                  },
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  color: Colors.red,
                                                ),
                                                IconButton(
                                                  onPressed: () async {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (_) => GpThreadMessage(
                                                                channelID: widget
                                                                    .channelID,
                                                                channelStatus:
                                                                    widget
                                                                        .channelStatus,
                                                                channelName: widget
                                                                    .channelName,
                                                                messageID:
                                                                    tGroupMessages![index]
                                                                        .id,
                                                                message:
                                                                    message,
                                                                name: retrieveGroupMessage!
                                                                    .tGroupMessages![
                                                                        index]
                                                                    .name
                                                                    .toString(),
                                                                time:
                                                                    created_at,
                                                                fname: retrieveGroupMessage!
                                                                    .tGroupMessages![
                                                                        index]
                                                                    .name
                                                                    .toString())));
                                                  },
                                                  icon: const Icon(Icons.reply),
                                                  color: const Color.fromARGB(
                                                      255, 15, 15, 15),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.star,
                                                    color: isStared
                                                        ? Colors.yellow
                                                        : Colors.grey,
                                                  ),
                                                  onPressed: () async {
                                                    if (_selectedMessageIndex !=
                                                        null) {
                                                      if (isStared) {
                                                        await _apiSerive.deleteGroupStarMessage(
                                                            tGroupMessages![
                                                                    index]
                                                                .id!,
                                                            widget.channelID!);
                                                      } else {
                                                        await _apiSerive
                                                            .getMessageStar(
                                                                tGroupMessages![
                                                                        index]
                                                                    .id!,
                                                                widget
                                                                    .channelID);
                                                      }
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.5,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                          bottomLeft: Radius.circular(10),
                                          bottomRight: Radius.zero,
                                        ),
                                        color:
                                            Color.fromARGB(110, 121, 120, 124),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (sendername.isNotEmpty)
                                              Text(
                                                sendername,
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            if (message.isNotEmpty)
                                              SelectableText(
                                                message,
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 0, 0, 0),
                                                ),
                                              ),
                                            if (files!.length == 1)
                                              singleFile.buildSingleFile(
                                                  files[0], context, platform),
                                            if (files.length > 2)
                                              mulitFile.buildMultipleFiles(
                                                  files, platform, context),
                                            const SizedBox(height: 8),
                                            const SizedBox(height: 8),
                                            Text(
                                              created_at,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color.fromARGB(
                                                    255, 15, 15, 15),
                                              ),
                                            ),
                                            RichText(
                                              text: TextSpan(
                                                text: '$count',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color.fromARGB(
                                                      255, 15, 15, 15),
                                                ),
                                                children: const [
                                                  WidgetSpan(
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 4.0),
                                                      child: Icon(Icons.reply),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.5,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                          bottomRight: Radius.circular(10),
                                          bottomLeft: Radius.zero,
                                        ),
                                        color:
                                            Color.fromARGB(111, 113, 81, 228),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (sendername.isNotEmpty)
                                              Text(
                                                sendername,
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            if (message.isNotEmpty)
                                              SelectableText(
                                                message,
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 0, 0, 0),
                                                ),
                                              ),
                                            if (files != null &&
                                                files.isNotEmpty)
                                              ...files.length == 1
                                                  ? [
                                                      singleFile
                                                          .buildSingleFile(
                                                              files.first,
                                                              context,
                                                              platform)
                                                    ]
                                                  : [
                                                      mulitFile
                                                          .buildMultipleFiles(
                                                              files,
                                                              platform,
                                                              context)
                                                    ],
                                            const SizedBox(height: 8),
                                            Text(
                                              created_at,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            RichText(
                                              text: TextSpan(
                                                text: '$count',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color.fromARGB(
                                                      255, 15, 15, 15),
                                                ),
                                                children: const [
                                                  WidgetSpan(
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 4.0),
                                                      child: Icon(Icons.reply),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_selectedMessageIndex ==
                                            channelStar[index].id &&
                                        !isSelected)
                                      Align(
                                        child: Container(
                                          padding: const EdgeInsets.all(3.0),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.star,
                                                    color: isStared
                                                        ? Colors.yellow
                                                        : Colors.grey,
                                                  ),
                                                  onPressed: () async {
                                                    if (_selectedMessageIndex !=
                                                        null) {
                                                      if (isStared) {
                                                        await _apiSerive.deleteGroupStarMessage(
                                                            tGroupMessages![
                                                                    index]
                                                                .id!,
                                                            widget.channelID!);
                                                      } else {
                                                        await _apiSerive
                                                            .getMessageStar(
                                                                tGroupMessages![
                                                                        index]
                                                                    .id!,
                                                                widget
                                                                    .channelID!);
                                                      }
                                                    }
                                                  },
                                                ),
                                                IconButton(
                                                  onPressed: () async {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (_) => GpThreadMessage(
                                                                channelID: widget
                                                                    .channelID,
                                                                channelStatus:
                                                                    widget
                                                                        .channelStatus,
                                                                channelName: widget
                                                                    .channelName,
                                                                messageID:
                                                                    tGroupMessages![index]
                                                                        .id,
                                                                message:
                                                                    message,
                                                                name: retrieveGroupMessage!
                                                                    .tGroupMessages![
                                                                        index]
                                                                    .name
                                                                    .toString(),
                                                                time:
                                                                    created_at,
                                                                fname: retrieveGroupMessage!
                                                                    .tGroupMessages![
                                                                        index]
                                                                    .name
                                                                    .toString())));
                                                  },
                                                  icon: const Icon(Icons.reply),
                                                  color: const Color.fromARGB(
                                                      255, 15, 15, 15),
                                                ),
                                                if (sendUserId == currentUserId)
                                                  IconButton(
                                                    onPressed: () async {
                                                      if (_selectedMessageIndex !=
                                                          null) {
                                                        await _apiSerive.deleteGroupMessage(
                                                            tGroupMessages![
                                                                    index]
                                                                .id!,
                                                            widget.channelID!);
                                                      }
                                                    },
                                                    icon: const Icon(
                                                        Icons.delete),
                                                    color: Colors.red,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )),
                if (hasFileToSEnd && files.isNotEmpty)
                  FileDisplayWidget(files: files, platform: platform),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: FlutterMentions(
                    key: key,
                    suggestionPosition: SuggestionPosition.Top,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                        hintText: 'send messages',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                pickFiles();
                              },
                              child: const Icon(
                                Icons.attach_file_outlined,
                                size: 35,
                              ),
                            ),
                            GestureDetector(
                                onTap: () {
                                  String message = key
                                      .currentState!.controller!.text
                                      .trimRight();
                                  int? channelId = widget.channelID;

                                  String mentionName = " ";
                                  List<String> userSearchItems = [];

                                  mention.forEach((data) {
                                    if (message
                                        .contains('@${data['display']}')) {
                                      mentionName = '@${data['display']}';

                                      userSearchItems.add(mentionName);
                                    }
                                  });

                                  sendGroupMessageData(
                                      message, channelId!, userSearchItems);
                                  key.currentState!.controller!.text = " ";
                                },
                                child: Icon(Icons.telegram,
                                    color: Colors.blue, size: 35))
                          ],
                        )),
                    mentions: [
                      Mention(
                          trigger: '@',
                          style: TextStyle(
                            color: Colors.blue,
                          ),
                          data: mention,
                          matchAll: false,
                          suggestionBuilder: (data) {
                            return Container(
                              color: Colors.grey.shade200,
                              padding: EdgeInsets.all(10.0),
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 20.0,
                                  ),
                                  Column(
                                    children: <Widget>[
                                      //  Text(data['display']),
                                      Text('@${data['display']}'),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
