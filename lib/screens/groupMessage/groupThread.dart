import 'dart:async';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/model/group_thread_list.dart';
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

class _GpThreadMessageState extends State<GpThreadMessage> with RouteAware {
  late ScrollController _scrollController;
  final StreamController<GroupThreadMessage> _control =
      StreamController<GroupThreadMessage>();
  late Timer _timer;
  bool isButtom = false;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _control.close();

    key.currentState!.controller!.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _scrollController.dispose();
    _startTimer();
  }

  void _startTimer() async {
    if (!isLoading) {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        try {
          final token = await getToken();
          GroupThreadMessage gpThread = await groupThreadService.getAllThread(
              widget.messageID, widget.channelID, token!);
          _control.add(gpThread);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } catch (e) {
          print(e);
        }
      });
    }
  }

  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  final groupThreadService = GroupThreadServices(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  TextEditingController threadMessage = TextEditingController();
  void _sendGpThread() async {
    String message = threadMessage.text;
    int? channelId = widget.channelID;
    String mention = '';
    await GpThreadMsg()
        .sendGroupThreadData(message, channelId!, widget.messageID, mention);
    if (message.isEmpty) {
      setState(() {
        groupThread = message;
      });
    }
    threadMessage.text = "";
  }

  GroupThreadMessage groupThreadList = GroupThreadMessage();
  String? groupThread;
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

  Future<void> sendGroupThreadData(String groupMessage, int channelID,
      int messageID, List<String> mentionName) async {
    final token = await getToken();
    try {
      await groupThreadService.sendGroupThreadData({
        "s_group_message_id": messageID,
        "s_channel_id": channelID,
        "message": groupMessage,
        "memtion_name": mentionName
      }, token!);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    dynamic channel = widget.channelStatus ? "public" : "private";
    String threadMsg = widget.message.toString();
    int maxLiane = (threadMsg.length / 15).ceil();

    if (SessionStore.sessionData!.currentUser!.memberStatus == true) {
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
          body: GestureDetector(
            onTap: () {
              setState(() {
                isButtom = true;
              });
            },
            child: StreamBuilder(
                stream: _control.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ProgressionBar(
                      imageName: 'loading.json',
                      height: 200,
                      size: 200,
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error : ${snapshot.error}'),
                    );
                  } else if (snapshot.data == null) {
                    return ProgressionBar(
                      imageName: 'dataSending.json',
                      height: 200,
                      size: 200,
                    );
                  } else {
                    int replyLength = snapshot.data!.GpThreads!.length.toInt();
                    GroupThreadMessage groupMessageList = snapshot.data!;
                    List<Map<String, Object?>> mention =
                        groupMessageList.TChannelUsers!.map((e) {
                      return {'display': e.name, 'name': e.name};
                    }).toList();
                    List<String> initials = widget.fname!
                        .split(" ")
                        .map((e) => e.substring(0, 1))
                        .toList();
                    String gpname = initials.join("");

                    return Padding(
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
                                            gpname.toUpperCase(),
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
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            widget.name.toString(),
                                            style:
                                                const TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            widget.time.toString(),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
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
                                            widget.message.toString(),
                                            maxLines: maxLiane,
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
                              int GpThreadID =
                                  snapshot.data!.GpThreads![index].id!.toInt();
                              String message = snapshot
                                  .data!.GpThreads![index].groupthreadmsg
                                  .toString();
                              int currentUser = SessionStore
                                  .sessionData!.currentUser!.id!
                                  .toInt();
                              int sendUserId = snapshot
                                  .data!.GpThreads![index].sendUserId!
                                  .toInt();
                              String name = snapshot
                                  .data!.GpThreads![index].name
                                  .toString();
                              List<String> initials = name
                                  .split(" ")
                                  .map((e) => e.substring(0, 1))
                                  .toList();
                              String groupThread = initials.join("");
                              String time = snapshot
                                  .data!.GpThreads![index].created_at
                                  .toString();
                              DateTime date = DateTime.parse(time).toLocal();
                              String createdAt =
                                  DateFormat('MMM d, yyyy hh:mm a')
                                      .format(date);
                              List groupThreadStarIds =
                                  snapshot.data!.GpThreadStar!.toList();
                              bool isStar = groupThreadStarIds.contains(
                                  snapshot.data!.GpThreads![index].id);
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
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
                                            borderRadius:
                                                const BorderRadius.only(
                                                    bottomLeft:
                                                        Radius.circular(13),
                                                    bottomRight:
                                                        Radius.circular(13),
                                                    topRight:
                                                        Radius.circular(13))),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    message,
                                                    style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    maxLines: 100000,
                                                  ),
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
                                                        .contains(GpThreadID)) {
                                                      try {
                                                        GpThreadMsg()
                                                            .unStarThread(
                                                                GpThreadID,
                                                                widget
                                                                    .channelID,
                                                                widget
                                                                    .messageID);
                                                      } catch (e) {
                                                        rethrow;
                                                      }
                                                    } else {
                                                      GpThreadMsg()
                                                          .sendStarThread(
                                                              GpThreadID,
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
                                                              GpThreadID,
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FlutterMentions(
                            key: key,
                            suggestionPosition: SuggestionPosition.Top,
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(
                                hintText: 'send threads',
                                suffixIcon: GestureDetector(
                                    onTap: () {
                                      // _sendGpThread();
                                      String name = key
                                          .currentState!.controller!.text
                                          .trimRight();
                                      int? channel_id = widget.channelID;

                                      String mentionName = " ";
                                      List<String> userSearchItems = [];
                                      mention.forEach((data) {
                                        if (name
                                            .contains('@${data['display']}')) {
                                          mentionName = '@${data['display']}';

                                          userSearchItems.add(mentionName);
                                        }
                                      });

                                      sendGroupThreadData(name, channel_id!,
                                          widget.messageID!, userSearchItems);
                                      key.currentState!.controller!.text = " ";
                                    },
                                    child: Icon(
                                      Icons.telegram,
                                      color: Colors.blue,
                                      size: 35,
                                    ))),
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
                    );
                  }
                }),
          ));
    } else {
      return CustomLogOut();
    }
  }
}
