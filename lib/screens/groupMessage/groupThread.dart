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
import 'package:flutter_frontend/model/group_thread_list.dart';
import 'package:flutter_frontend/services/groupMessageService/group_message_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/services/groupThreadApi/groupThreadService.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/groupThreadApi/retrofit/groupThread_services.dart';

// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, must_be_immutable, override_on_non_overriding_member

// ignore: depend_on_referenced_packages

class GpThreadMessage extends StatefulWidget {
  String? name, fname, time, message, channelName;
  final messageID, channelID;
  final channelStatus;
  GpThreadMessage(
      {super.key,
      this.name,
      this.fname,
      this.time,
      this.message,
      this.messageID,
      this.channelID,
      this.channelStatus,
      this.channelName});

  @override
  State<GpThreadMessage> createState() => _GpThreadMessageState();
}

class _GpThreadMessageState extends State<GpThreadMessage> {
  late ScrollController _scrollController;

  WebSocketChannel? _channel;
  List<gpThreads>? groupThreadData = [];
  List<dynamic>? groupThreadStar = [];
  List<mChannelUser>? channelUser = [];
  List<mUsers>? mUser = [];

  bool isButtom = false;
  bool isLoading = false;
  bool hasFileToSEnd = false;
  List<PlatformFile> files = [];
  late String localpath;
  late bool permissionReady;
  TargetPlatform? platform;
  final PermissionClass permissions = PermissionClass();
  String? fileText;

  BuildSingleFile singleFile = BuildSingleFile();
  BuildMulitFile mulitFile = BuildMulitFile();
  late List<Map<String, Object?>> mention;

  @override
  void initState() {
    super.initState();
    loadMessage();
    connectWebSocket();
    _scrollController = ScrollController();
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
    key.currentState!.controller!.dispose();
    _channel!.sink.close();
    super.dispose();
  }

  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  final _apiService = GroupThreadServices(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  final _groupThreadService = GroupMessageServiceImpl();

  TextEditingController threadMessage = TextEditingController();
  int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
  void _sendGpThread() async {
    String message = threadMessage.text;
    int? channelId = widget.channelID;
    String mention = '';
    await GpThreadMsg()
        .sendGroupThreadData(message, channelId!, widget.messageID, mention);
    if (message.isEmpty) {
      setState(() {
        // groupThread = message;
      });
    }
    threadMessage.text = "";
  }

  GroupThreadMessage groupThreadList = GroupThreadMessage();
  // String? groupThread;
  Future<String?> getToken() async {
    return await AuthController().getToken();
  }

  void _scrollToBottom() {
    if (isButtom) return;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void connectWebSocket() {
    var url =
        'ws://localhost:3000/cable?channel_id=${widget.channelID}&channel_name=${widget.channelName}&reply_to${widget.messageID}';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'GroupThreadChannel'}),
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
                  msg.containsKey('groupthreadmsg') &&
                  msg['t_group_message_id'] == widget.messageID) {
                var groupThreadMessage = msg['groupthreadmsg'];
                int id = msg['id'];
                var date = msg['created_at'];
                int mUserId = msg['m_user_id'];
                List<dynamic> fileUrls = [];
                String name = messageContent['sender_name'];

                if (messageContent.containsKey('files')) {
                  var files = messageContent['files'];
                  if (files != null) {
                    fileUrls = files.map((file) => file['file']).toList();
                  }
                }

                setState(() {
                  groupThreadData?.add(gpThreads(
                      id: id,
                      groupthreadmsg: groupThreadMessage,
                      created_at: date,
                      sendUserId: mUserId,
                      name: name,
                      fileUrls: fileUrls));
                });
              } else {}
            } else if (messageContent.containsKey('messaged_star')) {
              var messageStarData = messageContent['messaged_star'];

              if (messageStarData != null &&
                  messageStarData['userid'] == currentUserId) {
                int groupthreadid = messageStarData['groupthreadid'];

                setState(() {
                  groupThreadStar?.add(groupthreadid);
                });
              } else {}
            } else if (messageContent.containsKey('unstared_message')) {
              var unstaredMsg = messageContent['unstared_message'];

              if (unstaredMsg != null &&
                  unstaredMsg['userid'] == currentUserId) {
                var unstaredMsgId = unstaredMsg['groupthreadid'];

                setState(() {
                  groupThreadStar?.removeWhere(
                    (element) => element == unstaredMsgId,
                  );
                });
              }
            } else {
              var deletemsg = messageContent['delete_msg'];

              int id = deletemsg['id'];

              setState(() {
                groupThreadData?.removeWhere(
                  (element) => element.id == id,
                );
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

  void loadMessage() async {
    var token = await getToken();
    GroupThreadMessage data = await _apiService.getAllThread(
        widget.messageID, widget.channelID, token!);

    setState(() {
      groupThreadData = data.GpThreads;
      groupThreadStar = data.GpThreadStar;
      channelUser = data.TChannelUsers;
      mUser = data.MUsers;
      isLoading = true;
    });

    mention = channelUser!.map(
      (e) {
        return {'display': e.name, 'name': e.name};
      },
    ).toList();
  }

  Future<void> sendGroupThreadData(String groupMessage, int channelID,
      int messageID, List<String> mentionName) async {
    if (groupMessage.isNotEmpty || files.isNotEmpty) {
      await _groupThreadService.sendGroupThreadData(
          groupMessage, channelID, messageID, mentionName, files);
      files.clear();
    }
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
    dynamic channel = widget.channelStatus ? "public" : "private";
    String threadMsg = widget.message.toString();
    int? maxLiane = (threadMsg.length / 15).ceil();

    if (SessionStore.sessionData!.currentUser!.memberStatus == true) {
      int replyLength = groupThreadData!.length;
      List<String> initials =
          widget.fname!.split(" ").map((e) => e.substring(0, 1)).toList();
      String groupName = initials.join("");
      return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: kPriamrybackground,
          appBar: AppBar(
            backgroundColor: navColor,
            leading: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                )),
            title: Column(
              children: [
                ListTile(
                  title: Text(
                    "Message",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text("${channel} : ${widget.channelName}",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          body: isLoading == false
              ? ProgressionBar(
                  imageName: 'loading.json', height: 200, size: 200)
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      isButtom = true;
                    });
                  },
                  child: Padding(
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
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    height: 50,
                                    width: 50,
                                    child: FittedBox(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: Text(
                                          groupName.toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          widget.name.toString(),
                                          style: const TextStyle(fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          widget.time.toString(),
                                          style: const TextStyle(
                                              fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Container(
                                      height: 70,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: Text(
                                          widget.message!.isNotEmpty ? widget.message.toString() : "",
                                          maxLines: maxLiane == 0 ? 5 : maxLiane,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
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
                            int groupThreadId =
                                groupThreadData![index].id!.toInt();

                            String message = groupThreadData![index]
                                .groupthreadmsg
                                .toString();
                            int currentUser = SessionStore
                                .sessionData!.currentUser!.id!
                                .toInt();
                            int sendUserId =
                                groupThreadData![index].sendUserId!.toInt();
                            String name =
                                groupThreadData![index].name.toString();

                            List<dynamic>? files = [];
                            files = groupThreadData![index].fileUrls;

                            List<String> initials = name
                                .split(" ")
                                .map((e) => e.substring(0, 1))
                                .toList();
                            String groupThread = initials.join("");
                            String time =
                                groupThreadData![index].created_at.toString();
                            DateTime date = DateTime.parse(time).toLocal();
                            String createdAt =
                                DateFormat('MMM d, yyyy hh:mm a').format(date);
                            List groupThreadStarIds = groupThreadStar!.toList();
                            bool isStar = groupThreadStarIds
                                .contains(groupThreadData![index].id);
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Column(
                                      children: [
                                        Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.amber,
                                          ),
                                          height: 50,
                                          width: 50,
                                          child: FittedBox(
                                            alignment: Alignment.center,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(3.0),
                                              child: Text(
                                                groupThread.toUpperCase(),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        )
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
                                                if (message.isNotEmpty)
                                                  Text(
                                                    message,
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
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  if (groupThreadStarIds
                                                      .contains(
                                                          groupThreadId)) {
                                                    try {
                                                      GpThreadMsg()
                                                          .unStarThread(
                                                              groupThreadId,
                                                              widget.channelID,
                                                              widget.messageID);
                                                    } catch (e) {
                                                      rethrow;
                                                    }
                                                  } else {
                                                    GpThreadMsg()
                                                        .sendStarThread(
                                                            groupThreadId,
                                                            widget.channelID,
                                                            widget.messageID);
                                                  }
                                                },
                                                icon: isStar
                                                    ? Icon(
                                                        Icons.star,
                                                        color: Colors.yellow,
                                                      )
                                                    : Icon(Icons
                                                        .star_border_outlined),
                                              ),
                                              if (currentUser == sendUserId)
                                                IconButton(
                                                  onPressed: () {
                                                    GpThreadMsg()
                                                        .deleteGpThread(
                                                            groupThreadId,
                                                            widget.channelID,
                                                            widget.messageID);
                                                  },
                                                  icon: Icon(
                                                    Icons.delete,
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
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FlutterMentions(
                          key: key,
                          suggestionPosition: SuggestionPosition.Top,
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                              hintText: 'send threads',
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
                                        // _sendGpThread();
                                        String groupThreadName = key
                                            .currentState!.controller!.text
                                            .trimRight();
                                        int? channel_id = widget.channelID;

                                        String mentionName = " ";
                                        List<String> userSearchItems = [];
                                        mention.forEach((data) {
                                          if (groupThreadName.contains(
                                              '@${data['display']}')) {
                                            mentionName = '@${data['display']}';

                                            userSearchItems.add(mentionName);
                                          }
                                        });

                                        sendGroupThreadData(
                                            groupThreadName,
                                            channel_id!,
                                            widget.messageID!,
                                            userSearchItems);
                                        key.currentState!.controller!.text =
                                            " ";
                                      },
                                      child: Icon(
                                        Icons.telegram,
                                        color: Colors.blue,
                                        size: 35,
                                      ))
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
                      )
                    ]),
                  )));
    } else {
      return CustomLogOut();
    }
  }
}
