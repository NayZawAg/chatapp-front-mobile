import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/const/build_fiile.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';

import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/direct_message.dart';
import 'package:flutter_frontend/services/directMessage/direct_message_api.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/screens/directThreadMessage/direct_message_thread.dart';
import 'package:flutter_frontend/services/directMessage/directMessage/direct_meessages.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum SampleItem { itemOne, itemTwo, itemThree }

class DirectMessageWidget extends StatefulWidget {
  final int userId;
  final String receiverName;
  final user_status;

  const DirectMessageWidget({
    Key? key,
    required this.userId,
    this.user_status,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<DirectMessageWidget> createState() => _DirectMessageWidgetState();
}

class _DirectMessageWidgetState extends State<DirectMessageWidget> {
  final DirectMessageService directMessageService = DirectMessageService();
  final TextEditingController messageTextController = TextEditingController();
  String currentUserName =
      SessionStore.sessionData!.currentUser!.name.toString();
  int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
  List<TDirectMessages>? tDirectMessages = [];
  List<TempDirectStarMsgids>? tempDirectStarMsgids = [];
  List<int>? tempStarMsgids = [];
  WebSocketChannel? _channel;
  late ScrollController _scrollController;
  BuildMulitFile mulitFile = BuildMulitFile();
  BuildSingleFile singleFile = BuildSingleFile();

  final _apiService = ApiService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  bool isreading = false;
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

  @override
  void initState() {
    super.initState();

    loadMessages();
    connectWebSocket();
    if (kIsWeb) {
      return;
    } else if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    messageTextController.dispose();
    _channel!.sink.close();
  }

  void connectWebSocket() {
    var url =
        'ws://localhost:3000/cable?user_id=$currentUserId&s_user_id=${widget.userId}';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'ChatChannel'}),
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
                  msg.containsKey('directmsg') &&
                  ((msg['send_user_id'] == currentUserId &&
                          msg['receive_user_id'] == widget.userId) ||
                      (msg['send_user_id'] == widget.userId &&
                          msg['receive_user_id'] == currentUserId))) {
                var directmsg = msg['directmsg'];
                int id = msg['id'];
                var date = msg['created_at'];
                String send = messageContent['sender_name'];
                List<dynamic> fileUrls = [];

                if (messageContent.containsKey('files')) {
                  var files = messageContent['files'];
                  if (files != null) {
                    fileUrls = files.map((file) => file['file']).toList();
                  }
                }

                setState(() {
                  tDirectMessages!.add(TDirectMessages(
                    id: id,
                    directmsg: directmsg,
                    createdAt: date,
                    name: send,
                    fileUrls: fileUrls,
                  ));
                });
              } else {}
            }
            // Handling message star
            else if (messageContent.containsKey('messaged_star')) {
              var messageStarData = messageContent['messaged_star'];

              if (messageStarData != null &&
                  messageStarData['userid'] == currentUserId) {
                var starId = messageStarData['id'];
                var directMsgId = messageStarData['directmsgid'];

                setState(() {
                  tempDirectStarMsgids!.add(TempDirectStarMsgids(
                      directmsgid: directMsgId, id: starId));
                  tempStarMsgids!.add(directMsgId);
                });
              } else {}
            } else if (messageContent.containsKey('unstared_message') &&
                messageContent['unstared_message']['userid'] == currentUserId) {
              var unstaredMsg = messageContent['unstared_message'];
              var directmsgid = unstaredMsg['directmsgid'];

              setState(() {
                tempStarMsgids
                    ?.removeWhere((element) => element == directmsgid);
                tempDirectStarMsgids?.removeWhere(
                    (element) => element.directmsgid == directmsgid);
              });
            } else {
              var deletemsg = messageContent['delete_msg'];
              var id = deletemsg['id'];
              var directmsg = deletemsg['directmsg'];

              setState(() {
                tDirectMessages?.removeWhere((element) => element.id == id);
                tempDirectStarMsgids?.removeWhere(
                    (element) => element.directmsgid == directmsg);
              });
            }
          } else {}
        } catch (e) {}
      },
      onDone: () {
        _channel!.sink.close();
      },
      onError: (error) {},
    );
  }

  Future<void> loadMessages() async {
    var token = await getToken();
    try {
      DirectMessages messagess = await _apiService.getAllDirectMessages(
          widget.userId, token.toString());

      setState(() {
        tDirectMessages = messagess.tDirectMessages;
        tempDirectStarMsgids = messagess.tempDirectStarMsgids;
        tempStarMsgids = messagess.tDirectStarMsgids;
      });
    } catch (e) {}
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendMessage() async {
    if (messageTextController.text.isNotEmpty || files.isNotEmpty) {
      try {
        await directMessageService.sendDirectMessage(
            widget.userId, messageTextController.text.trimRight(), files);
        messageTextController.clear();
        files.clear();
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<String?> getToken() async {
    return await AuthController().getToken();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPriamrybackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            setState(() {
              isreading = !isreading;
            });
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
            Stack(children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber,
                ),
                height: 50,
                width: 50,
                child: Center(
                  child: Text(
                    widget.receiverName.isNotEmpty
                        ? "${widget.receiverName.characters.first.toUpperCase()}"
                        : "",
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                  right: 0,
                  bottom: 0,
                  child: widget.user_status
                      ? Container(
                          height: 14,
                          width: 14,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: Colors.white, width: 1),
                              color: Colors.green),
                        )
                      : Container())
            ]),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.receiverName.toUpperCase()}",
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView.builder(
            itemCount: tDirectMessages!.length,
            itemBuilder: (context, index) {
              if (tDirectMessages == null || tDirectMessages!.isEmpty) {
                return Container();
              }

              var channelStar = tDirectMessages!;

              List<dynamic>? files = [];
              files = tDirectMessages![index].fileUrls;

              List<int> tempStar = tempStarMsgids?.toList() ?? [];
              bool isStared = tempStar.contains(channelStar[index].id);

              String message = channelStar[index].directmsg ?? "";

              int count = channelStar[index].count ?? 0;
              String time = channelStar[index].createdAt.toString();
              DateTime date = DateTime.parse(time).toLocal();

              String created_at =
                  DateFormat('MMM d, yyyy hh:mm a').format(date);
              bool isMessageFromCurrentUser =
                  currentUserName == channelStar[index].name;
              int directMsgIds = channelStar[index].id ?? 0;

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
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          IconButton(
                                            onPressed: () async {
                                              if (_selectedMessageIndex !=
                                                  null) {
                                                await directMessageService
                                                    .deleteMsg(
                                                        _selectedMessageIndex!);
                                              }
                                            },
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red,
                                          ),
                                          IconButton(
                                            onPressed: () async {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          DirectMessageThreadWidget(
                                                              userstatus:
                                                                  widget
                                                                      .user_status,
                                                              receiverId:
                                                                  widget.userId,
                                                              directMsgId:
                                                                  directMsgIds,
                                                              receiverName: widget
                                                                  .receiverName)));
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
                                                  await directMessageService
                                                      .directUnStarMsg(
                                                          _selectedMessageIndex!);
                                                } else {
                                                  await directMessageService
                                                      .directStarMsg(
                                                          widget.userId,
                                                          _selectedMessageIndex!);
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
                                width: MediaQuery.of(context).size.width * 0.5,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.zero,
                                  ),
                                  color: Color.fromARGB(110, 121, 120, 124),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (message.isNotEmpty)
                                        SelectableText(
                                          message,
                                          style: const TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
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
                                          color:
                                              Color.fromARGB(255, 15, 15, 15),
                                        ),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          text: '$count',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color:
                                                Color.fromARGB(255, 15, 15, 15),
                                          ),
                                          children: const [
                                            WidgetSpan(
                                              child: Padding(
                                                padding:
                                                    EdgeInsets.only(left: 4.0),
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
                                width: MediaQuery.of(context).size.width * 0.5,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                    bottomLeft: Radius.zero,
                                  ),
                                  color: Color.fromARGB(111, 113, 81, 228),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (message.isNotEmpty)
                                        SelectableText(
                                          message,
                                          style: const TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
                                          ),
                                        ),
                                      if (files != null && files.isNotEmpty)
                                        ...files.length == 1
                                            ? [
                                                singleFile.buildSingleFile(
                                                    files.first,
                                                    context,
                                                    platform)
                                              ]
                                            : [
                                                mulitFile.buildMultipleFiles(
                                                    files, platform, context)
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
                                            color:
                                                Color.fromARGB(255, 15, 15, 15),
                                          ),
                                          children: const [
                                            WidgetSpan(
                                              child: Padding(
                                                padding:
                                                    EdgeInsets.only(left: 4.0),
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
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
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
                                                  await directMessageService
                                                      .directUnStarMsg(
                                                          _selectedMessageIndex!);
                                                } else {
                                                  await directMessageService
                                                      .directStarMsg(
                                                          widget.userId,
                                                          _selectedMessageIndex!);
                                                }
                                              }
                                            },
                                          ),
                                          IconButton(
                                            onPressed: () async {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          DirectMessageThreadWidget(
                                                              userstatus:
                                                                  widget
                                                                      .user_status,
                                                              receiverId:
                                                                  widget.userId,
                                                              directMsgId:
                                                                  directMsgIds,
                                                              receiverName: widget
                                                                  .receiverName)));
                                            },
                                            icon: const Icon(Icons.reply),
                                            color: const Color.fromARGB(
                                                255, 15, 15, 15),
                                          ),
                                          IconButton(
                                            onPressed: () async {
                                              if (_selectedMessageIndex !=
                                                  null) {
                                                await directMessageService
                                                    .deleteMsg(
                                                        _selectedMessageIndex!);
                                              }
                                            },
                                            icon: const Icon(Icons.delete),
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
          TextFormField(
            controller: messageTextController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.send,
            maxLines: null,
            cursorColor: kPrimaryColor,
            decoration: InputDecoration(
              hintText: "Sends Messages",
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                      onTap: () {
                        pickFiles();
                      },
                      child: const Icon(
                        Icons.attach_file_outlined,
                        size: 30,
                      )),
                  const SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isreading = !isreading;
                      });
                      sendMessage();
                      setState(() {
                        hasFileToSEnd = false;
                      });
                    },
                    child: const Icon(
                      Icons.telegram_outlined,
                      size: 35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
