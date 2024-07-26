import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/direct_message.dart';
import 'package:flutter_frontend/model/direct_message_thread.dart';
import 'package:flutter_frontend/screens/directMessage/direct_message.dart';
import 'package:flutter_frontend/screens/directThreadMessage/direct_message_thread.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_frontend/model/dataInsert/thread_lists.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/threadMessages/thread_message_service.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;

class DirectThread extends StatefulWidget {
  const DirectThread({Key? key}) : super(key: key);

  @override
  State<DirectThread> createState() => _DirectThreadState();
}

class _DirectThreadState extends State<DirectThread> {
  // --------------------------------
  List<TDirectMsgEmojiCounts>? emojiCounts = [];
  List<ReactUserDataForDirectMsg>? reactUserData = [];
  // --------------------------------
  List<EmojiCountsforDirectThread>? emojiCountsForDirectThread = [];
  List<ReactUserDataForDirectThread>? reactUserDatasForDirectThread = [];
  // --------------------------------
  late Future<void> refreshFuture;
  final _starListService = ThreadService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  int userId = SessionStore.sessionData!.currentUser!.id!.toInt();
  BuildMulitFile mulitFile = BuildMulitFile();
  BuildSingleFile singleFile = BuildSingleFile();
  TargetPlatform? platform;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      return;
    } else if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }
    _fetchData();
    _refresh();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      var token = await getToken();
      var data = await _starListService.getAllThreads(userId, token!);
      if (mounted) {
        setState(() {
          ThreadStore.thread = data;
          emojiCounts = data.tDirectMsgEmojiCounts!;
          reactUserData = data.reactUsernames!;

          emojiCountsForDirectThread = data.emojiCounts!;
          reactUserDatasForDirectThread = data.reactUserDatas;
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refresh() async {
    await _fetchData();
  }

  Future<String?> getToken() async {
    return await AuthController().getToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPriamrybackground,
      body: LiquidPullToRefresh(
        onRefresh: _refresh,
        color: Colors.blue.shade100,
        animSpeedFactor: 200,
        showChildOpacityTransition: true,
        child: ListView.builder(
          itemCount: ThreadStore.thread!.directMsg!.length,
          itemBuilder: (context, index) {
            var snapshot = ThreadStore.thread;
            String otherUser = "";
            final directMessage = ThreadStore.thread!.directMsg![index];
            if (directMessage.senderId != userId) {
              otherUser = directMessage.name.toString();
            }
            for (dynamic direct_thread in ThreadStore.thread!.d_thread!) {
              if (directMessage.id == direct_thread.directMsgId) {
                if (userId != direct_thread.senderId) {
                  otherUser = direct_thread.name;
                }
              }
            }
            if (snapshot!.directMsg!.isEmpty) {
              return const ProgressionBar(
                imageName: 'dataSending.json',
                height: 200,
                size: 200,
              );
            } else {
              List directThreadList = snapshot.d_thread!
                  .where((element) =>
                      element.directMsgId == snapshot.directMsg![index].id)
                  .toList();

              var directMessageList = snapshot.directMsg;
              int directMsgId = directMessageList![index].id!.toInt();
              int receiverId = directMessageList[index].receiverId!.toInt();
              String dmName = directMessageList[index].name.toString();
              String receiverName =
                  directMessageList[index].receiverName.toString();
              int senderId = directMessageList[index].senderId!.toInt();
              bool? receiverActiveStatus =
                  directMessageList[index].activeStatus;
              bool? senderActiveStatus =
                  directMessageList[index].senderActiveStatus;
              String dmMessage = directMessageList[index].directmsg.toString();
              String dmTime = directMessageList[index].created_at.toString();
              DateTime dmConvert = DateTime.parse(dmTime).toLocal();
              String dmCreatedAt =
                  DateFormat('MMM d, yyyy hh:mm a').format(dmConvert);
              List<dynamic>? directFiles = [];
              directFiles = directMessageList[index]
                  .fileUrls
                  ?.where(
                    (file) => file != null,
                  )
                  .toList();

              List<dynamic>? directFileName = [];
              directFileName = directMessageList[index]
                  .fileName
                  ?.where(
                    (file) => file != null,
                  )
                  .toList();

              String? directProfileName = directMessageList[index].profileName;
              if (directProfileName != null && !kIsWeb) {
                directProfileName = MinioToIP.replaceMinioWithIP(
                    directProfileName, ipAddressForMinio);
              }

              bool? userstatus;
              for (var user in SessionStore.sessionData!.mUsers!) {
                if (user.name == dmName) {
                  userstatus = user.activeStatus;
                }
              }

              int threadLastLength = directThreadList.length <= 2
                  ? directThreadList.length
                  : (directThreadList.length + 3) - directThreadList.length;
              int leftMessageLength =
                  directThreadList.length - threadLastLength;
              String? currentUserName =
                  SessionStore.sessionData!.currentUser!.name;
              int? currentUserId = SessionStore.sessionData!.currentUser!.id;

              String? messageSendingName;
              bool? messageSendingActiveStatus;
              int? messageSendingId;
              String? messageSendingProfileImage;

              if (currentUserName == receiverName &&
                  currentUserId == receiverId) {
                messageSendingName = dmName;
                messageSendingActiveStatus = senderActiveStatus;
                messageSendingId = senderId;
              } else if (currentUserName == dmName &&
                  currentUserId == senderId) {
                messageSendingName = receiverName;
                messageSendingActiveStatus = receiverActiveStatus;
                messageSendingId = receiverId;
              }

              for (var user in SessionStore.sessionData!.mUsers!) {
                if (user.id == messageSendingId) {
                  messageSendingProfileImage = user.profileImage;
                }
              }

              if (messageSendingProfileImage != null && !kIsWeb) {
                messageSendingProfileImage = MinioToIP.replaceMinioWithIP(
                    messageSendingProfileImage, ipAddressForMinio);
              }

              return Container(
                padding: const EdgeInsets.only(top: 10),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(10),
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10))),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  DirectMessageWidget(
                                                    userId: messageSendingId!,
                                                    receiverName:
                                                        messageSendingName!,
                                                    activeStatus:
                                                        messageSendingActiveStatus,
                                                    user_status:
                                                        messageSendingActiveStatus,
                                                    profileImage:
                                                        messageSendingProfileImage,
                                                  )));
                                    },
                                    child: Text.rich(TextSpan(children: [
                                      WidgetSpan(
                                          child: Row(
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 10,
                                            color: messageSendingActiveStatus!
                                                ? Colors.green
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(
                                            width: 4,
                                          ),
                                          Text(
                                            messageSendingName!,
                                            style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ))
                                    ])),
                                  ),
                                  Text(
                                    (otherUser == "")
                                        ? "You"
                                        : "You and $otherUser",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const Divider(),
                                  Text.rich(TextSpan(children: [
                                    WidgetSpan(
                                        child: Row(
                                      children: [
                                        Container(
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Colors.white,
                                          ),
                                          child: Center(
                                            child: directProfileName == null ||
                                                    directProfileName.isEmpty
                                                ? const Icon(Icons.person)
                                                : ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    child: Image.network(
                                                      directProfileName,
                                                      fit: BoxFit.cover,
                                                      width: 40,
                                                      height: 40,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          dmName,
                                          style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ))
                                  ])),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                          child: Column(
                                        children: [
                                          if (dmMessage.isNotEmpty)
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.5,
                                              child: flutter_html.Html(
                                                data: dmMessage,
                                                style: {
                                                  ".ql-code-block":
                                                      flutter_html.Style(
                                                          backgroundColor:
                                                              Colors.grey[200],
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 5),
                                                          margin: flutter_html
                                                                  .Margins
                                                              .symmetric(
                                                                  vertical: 7)),
                                                  ".highlight":
                                                      flutter_html.Style(
                                                    display: flutter_html
                                                        .Display.inlineBlock,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    color: Colors.red,
                                                    padding: flutter_html
                                                            .HtmlPaddings
                                                        .symmetric(
                                                            horizontal: 10,
                                                            vertical: 5),
                                                  ),
                                                  "blockquote":
                                                      flutter_html.Style(
                                                    border: const Border(
                                                        left: BorderSide(
                                                            color: Colors.grey,
                                                            width: 5.0)),
                                                    margin: flutter_html.Margins
                                                        .symmetric(
                                                            vertical: 10.0),
                                                    padding: flutter_html
                                                            .HtmlPaddings
                                                        .only(left: 10),
                                                  ),
                                                  "ol": flutter_html.Style(
                                                    margin: flutter_html.Margins
                                                        .symmetric(
                                                            horizontal: 10),
                                                    padding: flutter_html
                                                            .HtmlPaddings
                                                        .symmetric(
                                                            horizontal: 10),
                                                  ),
                                                  "ul": flutter_html.Style(
                                                    display: flutter_html
                                                        .Display.inlineBlock,
                                                    padding: flutter_html
                                                            .HtmlPaddings
                                                        .symmetric(
                                                            horizontal: 10),
                                                    margin: flutter_html.Margins
                                                        .all(0),
                                                  ),
                                                  "pre": flutter_html.Style(
                                                    backgroundColor:
                                                        Colors.grey[300],
                                                    padding: flutter_html
                                                            .HtmlPaddings
                                                        .symmetric(
                                                            horizontal: 10,
                                                            vertical: 5),
                                                  ),
                                                  "code": flutter_html.Style(
                                                    display: flutter_html
                                                        .Display.inlineBlock,
                                                    backgroundColor:
                                                        Colors.grey[300],
                                                    color: Colors.red,
                                                    padding: flutter_html
                                                            .HtmlPaddings
                                                        .symmetric(
                                                            horizontal: 10,
                                                            vertical: 5),
                                                  )
                                                },
                                              ),
                                            ),
                                          if (directFiles!.length == 1 &&
                                              directFiles.isNotEmpty)
                                            singleFile.buildSingleFile(
                                                directFiles[0],
                                                context,
                                                platform,
                                                directFileName?.first ?? ''),
                                          if (directFiles.length >= 2 &&
                                              directFiles.isNotEmpty)
                                            mulitFile.buildMultipleFiles(
                                                directFiles,
                                                platform,
                                                context,
                                                directFileName ?? []),
                                        ],
                                      )),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9,
                                        child: Wrap(
                                            direction: Axis.horizontal,
                                            spacing: 7,
                                            children: List.generate(
                                                emojiCounts!.length, (index) {
                                              bool show = false;
                                              List userIds = [];
                                              List reactUsernames = [];

                                              if (emojiCounts![index]
                                                      .directmsgid ==
                                                  directMsgId) {
                                                for (dynamic reactUser
                                                    in reactUserData!) {
                                                  if (reactUser.directmsgid ==
                                                          emojiCounts![index]
                                                              .directmsgid &&
                                                      emojiCounts![index]
                                                              .emoji ==
                                                          reactUser.emoji) {
                                                    userIds
                                                        .add(reactUser.userId);
                                                    reactUsernames
                                                        .add(reactUser.name);
                                                  }
                                                } //reactUser for loop end

                                                if (userIds
                                                    .contains(currentUserId)) {
                                                  Container();
                                                }
                                              }
                                              for (int i = 0;
                                                  i < emojiCounts!.length;
                                                  i++) {
                                                if (emojiCounts![i]
                                                        .directmsgid ==
                                                    directMsgId) {
                                                  for (int j = 0;
                                                      j < reactUserData!.length;
                                                      j++) {
                                                    if (userIds.contains(
                                                        reactUserData![j]
                                                            .userId)) {
                                                      return Container(
                                                        width: 50,
                                                        height: 25,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(16),
                                                          border: Border.all(
                                                            color: userIds.contains(
                                                                    currentUserId)
                                                                ? Colors.green
                                                                : Colors
                                                                    .red, // Use emojiBorderColor here
                                                            width: 1,
                                                          ),
                                                          color: const Color
                                                              .fromARGB(226,
                                                              212, 234, 250),
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        child: TextButton(
                                                          onPressed: null,
                                                          onLongPress:
                                                              () async {
                                                            HapticFeedback
                                                                .heavyImpact();
                                                            await showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (BuildContext
                                                                        context) {
                                                                  return SimpleDialog(
                                                                    title:
                                                                        const Center(
                                                                      child:
                                                                          Text(
                                                                        "People Who React",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                20),
                                                                      ),
                                                                    ),
                                                                    children: [
                                                                      SizedBox(
                                                                        width: MediaQuery.of(context)
                                                                            .size
                                                                            .width,
                                                                        child: ListView
                                                                            .builder(
                                                                          shrinkWrap:
                                                                              true,
                                                                          itemCount:
                                                                              reactUsernames.length,
                                                                          itemBuilder:
                                                                              (context, index) {
                                                                            return SingleChildScrollView(
                                                                                child: SimpleDialogOption(
                                                                              onPressed: () => Navigator.pop(context),
                                                                              child: Center(
                                                                                child: Text(
                                                                                  "${reactUsernames[index]}",
                                                                                  style: const TextStyle(fontSize: 18, letterSpacing: 0.1),
                                                                                ),
                                                                              ),
                                                                            ));
                                                                          },
                                                                        ),
                                                                      )
                                                                    ],
                                                                  );
                                                                });
                                                          },
                                                          style: ButtonStyle(
                                                            padding:
                                                                WidgetStateProperty
                                                                    .all(EdgeInsets
                                                                        .zero),
                                                            minimumSize:
                                                                WidgetStateProperty
                                                                    .all(const Size(
                                                                        50,
                                                                        25)),
                                                          ),
                                                          child: Text(
                                                            '${emojiCounts![index].emoji} ${emojiCounts![index].emojiCount}',
                                                            style:
                                                                const TextStyle(
                                                              color: Colors
                                                                  .blueAccent,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                }
                                              }
                                              return Container();
                                            })),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  leftMessageLength != 0
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            DirectMessageThreadWidget(
                                                              directMsgId:
                                                                  directMsgId,
                                                              receiverId:
                                                                  receiverId,
                                                              files:
                                                                  directFiles,
                                                              filesName:
                                                                  directFileName,
                                                              profileImage:
                                                                  directProfileName,
                                                              userstatus:
                                                                  userstatus,
                                                              receiverName:
                                                                  dmName,
                                                            )));
                                              },
                                              child: Text(
                                                "$leftMessageLength more replies",
                                                style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 15),
                                              ),
                                            )
                                          ],
                                        )
                                      : const SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: threadLastLength,
                                    itemBuilder: (context, index) {
                                      String message = directThreadList[index]
                                          .directthreadmsg
                                          .toString();
                                      int replyMessagesIds =
                                          directThreadList[index].id.toInt();
                                      String senderName =
                                          directThreadList[index]
                                              .name
                                              .toString();

                                      String dateTime = directThreadList[index]
                                          .created_at
                                          .toString();
                                      DateTime time =
                                          DateTime.parse(dateTime).toLocal();
                                      String threadCreateAt =
                                          DateFormat('MMM d, yyyy hh:mm a')
                                              .format(time);

                                      List<dynamic>? threadFiles = [];
                                      threadFiles = directThreadList[index]
                                          .fileUrls
                                          ?.where((file) => file != null)
                                          .toList();

                                      List<dynamic>? threadFileName = [];
                                      threadFileName =
                                          directThreadList[index].fileNames;

                                      String? threadProfileName =
                                          directThreadList[index].profileImage;

                                      if (threadProfileName != null &&
                                          !kIsWeb) {
                                        threadProfileName =
                                            MinioToIP.replaceMinioWithIP(
                                                threadProfileName,
                                                ipAddressForMinio);
                                      }
                                      print(
                                          "Reply Message Ids ==> $replyMessagesIds");
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.only(top: 10),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.9,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      height: 40,
                                                      width: 40,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 247, 243, 243),
                                                      ),
                                                      child: Center(
                                                        child: threadProfileName ==
                                                                    null ||
                                                                threadProfileName
                                                                    .isEmpty
                                                            ? const Icon(
                                                                Icons.person)
                                                            : ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                child: Image
                                                                    .network(
                                                                  threadProfileName,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  width: 40,
                                                                  height: 40,
                                                                ),
                                                              ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5)
                                                  ],
                                                ),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey.shade300,
                                                        borderRadius:
                                                            const BorderRadius
                                                                .only(
                                                                topRight:
                                                                    Radius
                                                                        .circular(
                                                                            10),
                                                                bottomLeft:
                                                                    Radius
                                                                        .circular(
                                                                            10),
                                                                bottomRight: Radius
                                                                    .circular(
                                                                        10))),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            senderName,
                                                            style: const TextStyle(
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          Container(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.5,
                                                            child: flutter_html
                                                                .Html(
                                                              data: message,
                                                              style: {
                                                                ".ql-code-block": flutter_html.Style(
                                                                    backgroundColor:
                                                                        Colors.grey[
                                                                            200],
                                                                    padding: flutter_html.HtmlPaddings.symmetric(
                                                                        horizontal:
                                                                            10,
                                                                        vertical:
                                                                            5),
                                                                    margin: flutter_html
                                                                            .Margins
                                                                        .symmetric(
                                                                            vertical:
                                                                                7)),
                                                                ".highlight":
                                                                    flutter_html
                                                                        .Style(
                                                                  display: flutter_html
                                                                      .Display
                                                                      .inlineBlock,
                                                                  backgroundColor:
                                                                      Colors.grey[
                                                                          200],
                                                                  color: Colors
                                                                      .red,
                                                                  padding: flutter_html
                                                                          .HtmlPaddings
                                                                      .symmetric(
                                                                          horizontal:
                                                                              10,
                                                                          vertical:
                                                                              5),
                                                                ),
                                                                "blockquote":
                                                                    flutter_html
                                                                        .Style(
                                                                  border: const Border(
                                                                      left: BorderSide(
                                                                          color: Colors
                                                                              .grey,
                                                                          width:
                                                                              5.0)),
                                                                  margin: flutter_html
                                                                          .Margins
                                                                      .symmetric(
                                                                          vertical:
                                                                              10.0),
                                                                  padding: flutter_html
                                                                          .HtmlPaddings
                                                                      .only(
                                                                          left:
                                                                              10),
                                                                ),
                                                                "ol":
                                                                    flutter_html
                                                                        .Style(
                                                                  margin: flutter_html
                                                                          .Margins
                                                                      .symmetric(
                                                                          horizontal:
                                                                              10),
                                                                  padding: flutter_html
                                                                          .HtmlPaddings
                                                                      .symmetric(
                                                                          horizontal:
                                                                              10),
                                                                ),
                                                                "ul":
                                                                    flutter_html
                                                                        .Style(
                                                                  display: flutter_html
                                                                      .Display
                                                                      .inlineBlock,
                                                                  padding: flutter_html
                                                                          .HtmlPaddings
                                                                      .symmetric(
                                                                          horizontal:
                                                                              10),
                                                                  margin: flutter_html
                                                                          .Margins
                                                                      .all(0),
                                                                ),
                                                                "pre":
                                                                    flutter_html
                                                                        .Style(
                                                                  backgroundColor:
                                                                      Colors.grey[
                                                                          300],
                                                                  padding: flutter_html
                                                                          .HtmlPaddings
                                                                      .symmetric(
                                                                          horizontal:
                                                                              10,
                                                                          vertical:
                                                                              5),
                                                                ),
                                                                "code":
                                                                    flutter_html
                                                                        .Style(
                                                                  display: flutter_html
                                                                      .Display
                                                                      .inlineBlock,
                                                                  backgroundColor:
                                                                      Colors.grey[
                                                                          300],
                                                                  color: Colors
                                                                      .red,
                                                                  padding: flutter_html
                                                                          .HtmlPaddings
                                                                      .symmetric(
                                                                          horizontal:
                                                                              10,
                                                                          vertical:
                                                                              5),
                                                                )
                                                              },
                                                            ),
                                                          ),
                                                          if (threadFiles !=
                                                                  null &&
                                                              threadFiles
                                                                  .isNotEmpty) ...[
                                                            if (threadFiles
                                                                        .length ==
                                                                    1 &&
                                                                threadFiles
                                                                    .isNotEmpty)
                                                              singleFile.buildSingleFile(
                                                                  threadFiles[
                                                                      0],
                                                                  context,
                                                                  platform,
                                                                  threadFileName
                                                                          ?.first ??
                                                                      ''),
                                                            const SizedBox(
                                                                height: 4),
                                                            if (threadFiles
                                                                        .length >=
                                                                    2 &&
                                                                threadFiles
                                                                    .isNotEmpty)
                                                              mulitFile.buildMultipleFiles(
                                                                  threadFiles,
                                                                  platform,
                                                                  context,
                                                                  threadFileName ??
                                                                      []),
                                                          ],
                                                          Text(
                                                            threadCreateAt,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        10),
                                                          ),
                                                          const SizedBox(),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.9,
                                            child: Wrap(
                                                direction: Axis.horizontal,
                                                spacing: 7,
                                                children: List.generate(
                                                    emojiCountsForDirectThread!
                                                        .length, (index) {
                                                  List userIds = [];
                                                  List userNames = [];

                                                  if (emojiCountsForDirectThread![
                                                              index]
                                                          .directThreadId ==
                                                      replyMessagesIds) {
                                                    print(
                                                        "inside the first if condition");
                                                    for (dynamic reactUser
                                                        in reactUserDatasForDirectThread!) {
                                                      print(
                                                          "inside the first for loop");
                                                      if (reactUser
                                                                  .directThreadId ==
                                                              emojiCountsForDirectThread![
                                                                      index]
                                                                  .directThreadId &&
                                                          emojiCountsForDirectThread![
                                                                      index]
                                                                  .emoji ==
                                                              reactUser.emoji) {
                                                        print(
                                                            "inside the second if condition");
                                                        userIds.add(
                                                            reactUser.userId);
                                                        userNames.add(
                                                            reactUser.name);
                                                      }
                                                    } //reactUser for loop end
                                                  }
                                                  for (int i = 0;
                                                      i <
                                                          emojiCountsForDirectThread!
                                                              .length;
                                                      i++) {
                                                    if (emojiCountsForDirectThread![
                                                                i]
                                                            .directThreadId ==
                                                        replyMessagesIds) {
                                                      for (int j = 0;
                                                          j <
                                                              reactUserDatasForDirectThread!
                                                                  .length;
                                                          j++) {
                                                        if (userIds.contains(
                                                            reactUserDatasForDirectThread![
                                                                    j]
                                                                .userId)) {
                                                          return Container(
                                                            width: 50,
                                                            height: 25,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16),
                                                              border:
                                                                  Border.all(
                                                                color: userIds.contains(
                                                                        currentUserId)
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .red, // Use emojiBorderColor here
                                                                width: 1,
                                                              ),
                                                              color: const Color
                                                                  .fromARGB(
                                                                  226,
                                                                  212,
                                                                  234,
                                                                  250),
                                                            ),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            child: TextButton(
                                                              onPressed: null,
                                                              onLongPress:
                                                                  () async {
                                                                HapticFeedback
                                                                    .heavyImpact();
                                                                await showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    return SimpleDialog(
                                                                      title:
                                                                          const Center(
                                                                        child:
                                                                            Text(
                                                                          "People Who React",
                                                                          style:
                                                                              TextStyle(fontSize: 20),
                                                                        ),
                                                                      ),
                                                                      children: [
                                                                        SizedBox(
                                                                          width: MediaQuery.of(context)
                                                                              .size
                                                                              .width,
                                                                          child:
                                                                              ListView.builder(
                                                                            shrinkWrap:
                                                                                true,
                                                                            itemBuilder:
                                                                                (ctx, index) {
                                                                              return SingleChildScrollView(
                                                                                child: SimpleDialogOption(
                                                                                  onPressed: () => Navigator.pop(context),
                                                                                  child: Center(
                                                                                    child: Text(
                                                                                      "${userNames[index]}",
                                                                                      style: const TextStyle(fontSize: 18, letterSpacing: 0.1),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                            itemCount:
                                                                                userNames.length,
                                                                          ),
                                                                        )
                                                                      ],
                                                                    );
                                                                  },
                                                                );
                                                              },
                                                              style:
                                                                  ButtonStyle(
                                                                padding: WidgetStateProperty
                                                                    .all(EdgeInsets
                                                                        .zero),
                                                                minimumSize:
                                                                    WidgetStateProperty.all(
                                                                        const Size(
                                                                            50,
                                                                            25)),
                                                              ),
                                                              child: Text(
                                                                '${emojiCountsForDirectThread![index].emoji} ${emojiCountsForDirectThread![index].emojiCount}',
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .blueAccent,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    }
                                                  }
                                                  return Container();
                                                })),
                                          )
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                          style: TextButton.styleFrom(
                                              shape:
                                                  const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  8)),
                                                      side: BorderSide(
                                                          color: Colors.white,
                                                          width: 5))),
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        DirectMessageThreadWidget(
                                                          directMsgId:
                                                              directMsgId,
                                                          receiverId:
                                                              receiverId,
                                                          files: directFiles,
                                                          filesName:
                                                              directFileName,
                                                          profileImage:
                                                              directProfileName,
                                                          userstatus:
                                                              userstatus,
                                                          receiverName: dmName,
                                                        )));
                                          },
                                          child: const Text(
                                            "reply",
                                            style:
                                                TextStyle(color: Colors.black),
                                          ))
                                    ],
                                  ),
                                  const SizedBox(),
                                  Text(
                                    dmCreatedAt,
                                    style: const TextStyle(fontSize: 10),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
