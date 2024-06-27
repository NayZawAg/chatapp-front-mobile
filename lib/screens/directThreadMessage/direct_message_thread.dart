import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/const/build_fiile.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:flutter_frontend/services/directMessage/direct_message_api.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/model/direct_message_thread.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/directMessage/directMessageThread/direct_message_thread.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// ignore_for_file: public_member_api_docs, sort_constructors_first

class DirectMessageThreadWidget extends StatefulWidget {
  final int directMsgId;
  final String receiverName;
  final int receiverId;
  final userstatus;
  const DirectMessageThreadWidget(
      {Key? key,
      required this.directMsgId,
      required this.receiverName,
      required this.receiverId,
      this.userstatus})
      : super(key: key);

  @override
  State<DirectMessageThreadWidget> createState() => _DirectMessageThreadState();
}

class _DirectMessageThreadState extends State<DirectMessageThreadWidget> {
  final DirectMsgThreadService _apiService = DirectMsgThreadService(Dio(
      BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  final TextEditingController replyTextController = TextEditingController();
  final DirectMessageService _directMessageService = DirectMessageService();
  int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
  late ScrollController _scrollController;

  int? selectedIndex;

  bool isLoading = false;
  List<TDirectThreads>? tDirectThreads = [];
  List<int>? tDirectStarThreadMsgIds = [];
  String senderName = "";
  String directMessage = "";
  String times = DateTime.now().toString();
  List<PlatformFile> files = [];
  bool hasFileToSEnd = false;
  late String localpath;
  late bool permissionReady;
  TargetPlatform? platform;
  WebSocketChannel? _channel;
  final PermissionClass permissions = PermissionClass();
  String? fileText;
  BuildMulitFile mulitFile = BuildMulitFile();
  BuildSingleFile singleFile = BuildSingleFile();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    loadMessages();
    connectWebSocket();
    if (kIsWeb) {
      return;
    } else if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }
  }

  @override
  void dispose() {
    super.dispose();

    _scrollController.dispose();
    replyTextController.dispose();
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

  void connectWebSocket() {
    var url =
        'ws://localhost:3000/cable?user_id=$currentUserId&s_user_id=${widget.receiverId}';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'ThreadChannel'}),
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
                  msg.containsKey('directthreadmsg') &&
                  msg['t_direct_message_id'] == widget.directMsgId) {
                var directThreadMsg = msg['directthreadmsg'];
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
                  tDirectThreads!.add(TDirectThreads(
                    id: id,
                    directthreadmsg: directThreadMsg,
                    fileUrls: fileUrls,
                    createdAt: date,
                    name: send,
                  ));
                });
              } else {}
            } else if (messageContent.containsKey('messaged_star')) {
              var messageStarData = messageContent['messaged_star'];

              if (messageStarData != null &&
                  messageStarData['userid'] == currentUserId) {
                var directThreadID = messageStarData['directthreadid'];

                setState(() {
                  tDirectStarThreadMsgIds!.add(directThreadID);
                });
              } else {}
            } else if (messageContent.containsKey('unstared_message') &&
                messageContent['unstared_message']['userid'] == currentUserId) {
              var unstaredMsg = messageContent['unstared_message'];

              var directmsgid = unstaredMsg['directthreadid'];

              setState(() {
                tDirectStarThreadMsgIds!.remove(directmsgid);
              });
            } else {
              var deletemsg = messageContent['delete_msg_thread'];

              var threadId = deletemsg['id'];

              setState(() {
                tDirectThreads!.removeWhere((thread) {
                  return thread.id == threadId;
                });
              });
            }
          } else {}
        } catch (e) {
          rethrow;
        }
      },
      onDone: () {},
      onError: (error) {},
    );
  }

  Future<void> loadMessages() async {
    var token = await getToken();
    try {
      DirectMessageThread thread =
          await _apiService.getAllThread(widget.directMsgId, token!);

      setState(() {
        tDirectThreads = thread.tDirectThreads;
        tDirectStarThreadMsgIds = thread.tDirectStarThreadMsgids;
        senderName = thread.senderName!;
        directMessage = thread.tDirectMessage!.directmsg!;
        times = thread.tDirectMessage!.createdAt!;
        isLoading = true;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendReplyMessage() async {
    if (replyTextController.text.isNotEmpty || files.isNotEmpty) {
      await _directMessageService.sendDirectMessageThread(widget.directMsgId,
          widget.receiverId, replyTextController.text, files);
      replyTextController.clear();
      files.clear();
    }
  }

  Future<void> starMsgReply(int threadId) async {
    var token = await getToken();
    await _apiService.starThread(
        widget.receiverId, currentUserId, threadId, widget.directMsgId, token!);
  }

  Future<void> unStarReply(int threadId) async {
    var token = await getToken();
    await _apiService.unStarThread(
        widget.directMsgId, widget.receiverId, threadId, currentUserId, token!);
  }

  Future<void> deleteReply(int threadId) async {
    var token = await getToken();
    await _apiService.deleteThread(
        widget.directMsgId, widget.receiverId, threadId, token!);
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

  Future<String?> getToken() async {
    return await AuthController().getToken();
  }

  @override
  Widget build(BuildContext context) {
    if (SessionStore.sessionData!.currentUser!.memberStatus == false) {
      return const CustomLogOut();
    } else {
      DateTime dates = DateTime.parse(times).toLocal();
      String createdAt = DateFormat('MMM d, yyyy hh:mm a').format(dates);
      int maxLines = (directMessage.length / 25).ceil();
      int replyLength = tDirectThreads?.length ?? 0;

      return Scaffold(
          backgroundColor: kPriamrybackground,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: navColor,
            leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                )),
            title: const Text(
              'Thread',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: isLoading == false
              ? const ProgressionBar(
                  imageName: 'loading.json',
                  height: 200,
                  size: 200,
                  color: Colors.white)
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    SizedBox(
                      height: 100,
                      width: 500,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(20)),
                                  height: 50,
                                  width: 50,
                                  child: Center(
                                    child: Text(
                                      senderName.characters.first.toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: widget.userstatus == true
                                        ? Container(
                                            height: 14,
                                            width: 14,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 1),
                                                color: Colors.green),
                                          )
                                        : Container())
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Row(children: [
                                        Text(
                                          senderName,
                                          style: const TextStyle(fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          createdAt,
                                          style: const TextStyle(
                                              fontSize: 10, color: Colors.grey),
                                        )
                                      ]),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    directMessage.isNotEmpty
                                        ? directMessage
                                        : "",
                                    maxLines: maxLines == 0 ? 5 : maxLines,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              '$replyLength reply',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Divider(),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: replyLength,
                        itemBuilder: (context, index) {
                          String replyMessages =
                              tDirectThreads![index].directthreadmsg.toString();
                          String name = tDirectThreads![index].name.toString();

                          List<dynamic>? files = [];
                          files = tDirectThreads![index].fileUrls;

                          int replyMessagesIds =
                              tDirectThreads![index].id!.toInt();
                          List<int> replyStarMsgId =
                              tDirectStarThreadMsgIds!.toList();
                          bool isStar =
                              replyStarMsgId.contains(replyMessagesIds);
                          String time =
                              tDirectThreads![index].createdAt.toString();

                          DateTime date = DateTime.parse(time).toLocal();
                          String createdAt =
                              DateFormat('MMM d, yyyy hh:mm a').format(date);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Colors.amber,
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        height: 50,
                                        width: 50,
                                        child: Center(
                                          child: Text(
                                            name.characters.first.toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: widget.userstatus == true
                                              ? Container(
                                                  height: 14,
                                                  width: 14,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7),
                                                      border: Border.all(
                                                          color: Colors.white,
                                                          width: 1),
                                                      color: Colors.green),
                                                )
                                              : Container())
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(13),
                                            bottomRight: Radius.circular(13),
                                            topRight: Radius.circular(13))),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (replyMessages.isNotEmpty)
                                                Text(
                                                  replyMessages,
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  maxLines: 100000,
                                                ),
                                              if (files!.length == 1)
                                                singleFile.buildSingleFile(
                                                    files[0],
                                                    context,
                                                    platform),
                                              if (files.length > 2)
                                                mulitFile.buildMultipleFiles(
                                                    files, platform, context),
                                              const SizedBox(height: 8),
                                              const SizedBox(height: 8),
                                              Text(
                                                createdAt,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color.fromARGB(
                                                      255, 15, 15, 15),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          // crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              onPressed: () async {
                                                if (isStar) {
                                                  await unStarReply(
                                                      replyMessagesIds);
                                                } else {
                                                  await starMsgReply(
                                                      replyMessagesIds);
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.star,
                                                size: 20,
                                              ),
                                              color: isStar
                                                  ? Colors.yellow
                                                  : Colors.grey,
                                            ),
                                            IconButton(
                                              onPressed: () async {
                                                await deleteReply(
                                                    replyMessagesIds);
                                                print(
                                                    "This is a corona ${replyMessagesIds}");
                                              },
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 20,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (hasFileToSEnd && files.isNotEmpty)
                      FileDisplayWidget(files: files, platform: platform),
                    TextFormField(
                      controller: replyTextController,
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
                                sendReplyMessage();
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
                  ])));
    }
  }
}
