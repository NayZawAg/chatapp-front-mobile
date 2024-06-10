import 'dart:async';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/model/direct_message_thread.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/directMessage/directMessageThread/direct_message_thread.dart';
// ignore_for_file: public_member_api_docs, sort_constructors_first

class DirectMessageThreadWidget extends StatefulWidget {
  final int directMsgId;
  final String receiverName;
  final int receiverId;
  final user_status;
  const DirectMessageThreadWidget(
      {Key? key,
      required this.directMsgId,
      required this.receiverName,
      required this.receiverId,
      this.user_status})
      : super(key: key);

  @override
  State<DirectMessageThreadWidget> createState() => _DirectMessageThreadState();
}

class _DirectMessageThreadState extends State<DirectMessageThreadWidget>
    with RouteAware {
  final DirectMsgThreadService _apiService = DirectMsgThreadService(Dio(
      BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  final TextEditingController replyTextController = TextEditingController();
  final StreamController<DirectMessageThread> _controller =
      StreamController<DirectMessageThread>();
  int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
  late ScrollController _scrollController;

  int? selectedIndex;

  bool isLoading = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _starFetching();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
    _scrollController.dispose();
    replyTextController.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _starFetching();
  }

  Future<void> sendReplyMessage() async {
    Map<String, dynamic> requestBody = {
      "s_direct_message_id": widget.directMsgId,
      "s_user_id": widget.receiverId,
      "message": replyTextController.text,
      "user_id": currentUserId
    };
    if (replyTextController.text.isNotEmpty) {
      var token = await getToken();
      await _apiService.sentThread(requestBody, token!);
      replyTextController.clear();
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

  void _starFetching() async {
    if (!isLoading) {
      _timer = Timer.periodic(const Duration(seconds: 6), (timer) async {
        try {
          final token = await getToken();
          DirectMessageThread directMessageThread =
              await _apiService.getAllThread(widget.directMsgId, token!);
          _controller.add(directMessageThread);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } catch (e) {
          rethrow;
        }
      });
    }
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
      return CustomLogOut();
    } else {
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
        body: StreamBuilder<DirectMessageThread>(
            stream: _controller.stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ProgressionBar(
                    imageName: 'loading.json',
                    height: 200,
                    size: 200,
                    color: Colors.white);
              } else {
                var messageInfo = snapshot.data;
                String senderName = snapshot.data!.senderName!;
                String messages =
                    snapshot.data!.tDirectMessage!.directmsg!.toString();
                String times =
                    snapshot.data!.tDirectMessage!.createdAt.toString();

                DateTime dates = DateTime.parse(times).toLocal();
                String createdAt =
                    DateFormat('MMM d, yyyy hh:mm a').format(dates);

                int maxLines = (messages.length / 25).ceil();
                int replyLength = snapshot.data!.tDirectThreads!.length.toInt();
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
                                        senderName.characters.first
                                            .toUpperCase(),
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
                                      child: widget.user_status == true
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
                                            style:
                                                const TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            createdAt,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          )
                                        ]),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      messages,
                                      maxLines: maxLines,
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
                            String replyMessages = messageInfo!
                                .tDirectThreads![index].directthreadmsg
                                .toString();
                            String name = messageInfo
                                .tDirectThreads![index].name
                                .toString();

                            int replyMessagesIds =
                                messageInfo.tDirectThreads![index].id!.toInt();
                            List<int> replyStarMsgId =
                                messageInfo.tDirectStarThreadMsgids!.toList();
                            bool isStar =
                                replyStarMsgId.contains(replyMessagesIds);
                            String time = snapshot
                                .data!.tDirectThreads![index].createdAt
                                .toString();

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
                                              name.characters.first
                                                  .toUpperCase(),
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
                                            child: widget.user_status == true
                                                ? Container(
                                                    height: 14,
                                                    width: 14,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(7),
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
                                                Text(
                                                  replyMessages,
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
                                            // crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    selectedIndex =
                                                        replyMessagesIds;
                                                  });
                                                  if (isStar) {
                                                    await unStarReply(
                                                        selectedIndex!);
                                                  } else {
                                                    await starMsgReply(
                                                        selectedIndex!);
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
                                                        selectedIndex!);
                                                  },
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    size: 20,
                                                    color: Colors.red,
                                                  )),
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
                      TextFormField(
                        controller: replyTextController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.send,
                        cursorColor: kPrimaryColor,
                        maxLines: null,
                        decoration: InputDecoration(
                            hintText: "Send Threads",
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState() {
                                  isLoading = !isLoading;
                                }

                                sendReplyMessage();
                              },
                              child: const Icon(
                                Icons.telegram,
                                color: Colors.blue,
                                size: 35,
                              ),
                            )),
                      ),
                    ]));
              }
            }),
      );
    }
  }
}
