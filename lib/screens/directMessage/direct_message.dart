import 'dart:async';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/direct_message.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/services/directMessage/direct_message_api.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/screens/directThreadMessage/direct_message_thread.dart';
import 'package:flutter_frontend/services/directMessage/directMessage/direct_meessages.dart';

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

class _DirectMessageWidgetState extends State<DirectMessageWidget>
    with RouteAware {
  final DirectMessageService directMessageService = DirectMessageService();
  final TextEditingController messageTextController = TextEditingController();
  String currentUserName =
      SessionStore.sessionData!.currentUser!.name.toString();
  StreamController<DirectMessages> _controller =
      StreamController<DirectMessages>();
  late ScrollController _scrollController;

  final _apiService = ApiService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  bool isreading = false;
  bool isSelected = false;
  bool isStarred = false;
  int? _selectedMessageIndex;
  int? selectUserId;

  late Timer _timer;
  // final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.close();
    messageTextController.dispose();

    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _scrollController.dispose();
    _timer.cancel();
    // _startTimer(); // Restart the timer when returning to this page
  }

  @override
  void didPushNext() {
    super.didPushNext();
    _timer.cancel();
    // _startTimer();
  }

  void _startTimer() async {
    if (!isreading) {
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) async {
        try {
          final token = await getToken();
          DirectMessages directMessages =
              await _apiService.getAllDirectMessages(widget.userId, token!);
          _controller.add(directMessages);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } catch (e) {
          print("Error fetching messages: $e");
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

  Future<void> sendMessage() async {
    if (messageTextController.text.isNotEmpty) {
      await directMessageService.sendDirectMessage(
          widget.userId, messageTextController.text.trimRight());
      messageTextController.clear();
    }
  }

  Future<String?> getToken() async {
    return await AuthController().getToken();
  }

  String convertJapanToMyanmarTime(String japanTime) {
    DateTime japanDateTime = DateTime.parse(japanTime);

    DateTime myanmarDateTime =
        japanDateTime.add(const Duration(hours: -2, minutes: -30));

    String myanmarTime =
        DateFormat('MMM d, yyyy hh:mm a').format(myanmarDateTime);

    return myanmarTime;
  }

  @override
  Widget build(BuildContext context) {
    if(SessionStore.sessionData!.currentUser!.memberStatus == true) {
      return Scaffold(
      backgroundColor: kPriamrybackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            setState() {
              isreading = !isreading;
            }

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
            Stack(
              children:[ Container(
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
                  child:widget.user_status == true ?  Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.white,width: 1),
                    color: Colors.green
                  ),
                ):Container() )]
            ),
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
            child: StreamBuilder<DirectMessages>(
              stream: _controller.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError || !snapshot.hasData) {
                  return const ProgressionBar(
                      imageName: 'dataSending.json',
                      height: 200,
                      size: 200,
                     );
                } else {
                  final directMessages = snapshot.data!;
                  
                  int directMessage =
                      directMessages.tDirectMessages!.length.toInt();
                  return
                      ListView.builder(
                        controller: _scrollController,
                        itemCount: directMessage,
                        itemBuilder: (context, index) {
                          var channelStar = directMessages.tDirectMessages;
                          List<int> tempStar =
                              directMessages.tDirectStarMsgids!.toList();
                      
                          bool isStared =
                              tempStar.contains(channelStar![index].id);
                      
                          String message = directMessages
                              .tDirectMessages![index].directmsg!
                              .toString();
                      
                          int count = directMessages
                              .tDirectMessages![index].count!
                              .toInt();
                          String time = directMessages
                              .tDirectMessages![index].createdAt
                              .toString();
                          DateTime date = DateTime.parse(time).toLocal();
                      
                          String created_at =
                              DateFormat('MMM d, yyyy hh:mm a').format(date);
                      
                          bool isMessageFromCurrentUser = currentUserName ==
                              directMessages.tDirectMessages![index].name;
                          int directMsgIds =
                              directMessages.tDirectMessages![index].id!.toInt();
                      
                          return SingleChildScrollView(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedMessageIndex =
                                      directMessages.tDirectMessages![index].id;
                                  isSelected = !isSelected;
                                });
                              },
                              child: Container(
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
                                                    directMessages
                                                        .tDirectMessages![index]
                                                        .id &&
                                                !isSelected)
                                              Align(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(3.0),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(10.0),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(
                                                      bottom: 10,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        IconButton(
                                                          onPressed: () async {
                                                            await directMessageService
                                                                .deleteMsg(
                                                                    _selectedMessageIndex!);
                                                          },
                                                          icon: const Icon(
                                                              Icons.delete),
                                                          color: Colors.red,
                                                        ),
                                                        IconButton(
                                                          onPressed: () async {
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder: (_) => DirectMessageThreadWidget(
                                                                      user_status: widget.user_status,
                                                                        receiverId:
                                                                            widget
                                                                                .userId,
                                                                        directMsgId:
                                                                            directMsgIds,
                                                                        receiverName:
                                                                            widget
                                                                                .receiverName)));
                                                          },
                                                          icon: const Icon(
                                                              Icons.reply),
                                                          color:
                                                              const Color.fromARGB(
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
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              // constraints: const BoxConstraints(
                                              //     maxWidth: 200),
                                              decoration: const BoxDecoration(
                                                borderRadius: BorderRadius.only(
                                                    topLeft: Radius.circular(10),
                                                    topRight: Radius.circular(10),
                                                    bottomLeft: Radius.circular(10),
                                                    bottomRight: Radius.zero),
                                                color: Color.fromARGB(
                                                    110, 121, 120, 124),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    SelectableText(
                                                      message,
                                                      style: const TextStyle(
                                                        color: Color.fromARGB(
                                                            255, 0, 0, 0),
                                                      ),
                                                    ),
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
                                                              padding:
                                                                  EdgeInsets.only(
                                                                      left: 4.0),
                                                              child:
                                                                  Icon(Icons.reply),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              // constraints: const BoxConstraints(
                                              //     maxWidth: 200),
                                              decoration: const BoxDecoration(
                                                borderRadius: BorderRadius.only(
                                                    topLeft: Radius.circular(10),
                                                    topRight: Radius.circular(10),
                                                    bottomRight:
                                                        Radius.circular(10),
                                                    bottomLeft: Radius.zero),
                                                color: Color.fromARGB(
                                                    111, 113, 81, 228),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SelectableText(
                                                      message,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    ),
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
                                                              padding:
                                                                  EdgeInsets.only(
                                                                      left: 4.0),
                                                              child:
                                                                  Icon(Icons.reply),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (_selectedMessageIndex ==
                                                    directMessages
                                                        .tDirectMessages![index]
                                                        .id &&
                                                !isSelected)
                                              Align(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(3.0),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(10.0),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(
                                                      bottom: 8,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.star,
                                                            color: isStared
                                                                ? Colors.yellow
                                                                : Colors.grey,
                                                          ),
                                                          onPressed: () async {
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
                                                          },
                                                        ),
                                                        IconButton(
                                                          onPressed: () {
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder: (_) => DirectMessageThreadWidget(
                                                                      user_status: widget.user_status,
                                                                        receiverId:
                                                                            widget
                                                                                .userId,
                                                                        directMsgId:
                                                                            _selectedMessageIndex!,
                                                                        receiverName:
                                                                            widget
                                                                                .receiverName)));
                                                          },
                                                          icon: const Icon(
                                                              Icons.reply),
                                                          color:
                                                              const Color.fromARGB(
                                                                  255, 15, 15, 15),
                                                        ),
                                                        IconButton(
                                                          onPressed: () async {
                                                            await directMessageService
                                                                .deleteMsg(
                                                                    _selectedMessageIndex!);
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
                            ),
                          );
                        },
                      );
                    
                  
                }
              },
            ),
          ),
          
          TextFormField(
      controller: messageTextController,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.send,
      maxLines: null,
      cursorColor: kPrimaryColor,
      decoration: InputDecoration(
        hintText: "Sends Messages",
        suffixIcon: GestureDetector(
          onTap: () {
            setState() {
              isreading = !isreading;
            }
      
            sendMessage();
          },
          child: const Icon(
            Icons.telegram,
            color: Colors.blue,
            size: 35,
          ),
        ),
      ),
            ),
        ],
      ),
      // bottomSheet: TextFormField(
      //   controller: messageTextController,
      //   keyboardType: TextInputType.text,
      //   textInputAction: TextInputAction.send,
      //   cursorColor: kPrimaryColor,
      //   decoration: InputDecoration(
      //     hintText: "Sends Messages",
      //     suffixIcon: GestureDetector(
      //       onTap: () {
      //         setState() {
      //           isreading = !isreading;
      //         }

      //         sendMessage();
      //       },
      //       child: const Icon(
      //         Icons.telegram,
      //         color: Colors.blue,
      //         size: 35,
      //       ),
      //     ),
      //   ),
      // ),
    );
    }
    else {
      return CustomLogOut();
    }
  }
}
