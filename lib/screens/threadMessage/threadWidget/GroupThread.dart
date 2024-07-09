import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/group_thread_list.dart';
import 'package:flutter_frontend/screens/groupMessage/groupThread.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_frontend/model/dataInsert/thread_lists.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/threadMessages/thread_message_service.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;

class GroupThread extends StatefulWidget {
  const GroupThread({Key? key}) : super(key: key);

  @override
  State<GroupThread> createState() => _GroupThreadState();
}

class _GroupThreadState extends State<GroupThread> {
  late Future<void> refrshFuture;
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
    refrshFuture = _fetchData();
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
  }

  Future<void> _fetchData() async {
    try {
      var token = await getToken();
      var data = await _starListService.getAllThreads(userId, token!);
      if (mounted) {
        setState(() {
          ThreadStore.thread = data;
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
          itemCount: ThreadStore.thread!.groupMessage!.length,
          itemBuilder: (context, index) {
            var snapshot = ThreadStore.thread;
            final gpMsg = ThreadStore.thread!.groupMessage![index];
            List senderNames = [];
            String loginUserName = "";
            String result;
            if (gpMsg.senderId != userId) {
              senderNames.add(gpMsg.name);
            } else {
              loginUserName = 'とあなた';
            }

            for (dynamic gp_thread in ThreadStore.thread!.groupThread!) {
              if (gpMsg.id == gp_thread.groupMessageId) {
                if (userId != gp_thread.senderId) {
                  senderNames.add(gp_thread.name);
                } else {
                  loginUserName = 'とあなた';
                }
              }
            }

            List<dynamic> uniqueSenderNames = senderNames.toSet().toList();
            if (uniqueSenderNames.isEmpty) {
              result = "自分のみ";
            } else {
              result = uniqueSenderNames.join("さん, ") + "さん、" + loginUserName;
            }

            // Group message
            var directGroupList = snapshot!.groupMessage;
            int groupMsgId = directGroupList![index].id!.toInt();
            String name = directGroupList[index].name.toString();
            String groupMessage = directGroupList[index].groupmsg!.toString();
            String gpmsgTime = directGroupList[index].created_at!.toString();
            DateTime time = DateTime.parse(gpmsgTime).toLocal();
            String directmsgTime =
                DateFormat('MMM d, yyyy hh:mm a').format(time);

            List groupMessageThreadList = snapshot.groupThread!
                .where((element) => element.groupMessageId == groupMsgId)
                .toList();

            List<dynamic>? groupFiles = [];
            groupFiles = directGroupList[index]
                .fileUrls
                ?.where(
                  (element) => element != null,
                )
                .toList();
            String channelName = directGroupList[index].channelName.toString();

            return Container(
              padding: const EdgeInsets.only(top: 10),
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                children: [
                  Text(
                    channelName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(result),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: FittedBox(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Text(
                                  channelName.toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
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
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: flutter_html.Html(
                                    data: groupMessage,
                                    style: {
                                      ".bq": flutter_html.Style(
                                        border: const Border(
                                            left: BorderSide(
                                                color: Colors.grey,
                                                width: 5.0)),
                                        padding: flutter_html.HtmlPaddings.only(
                                            left: 10),
                                      ),
                                      "blockquote": flutter_html.Style(
                                        display: flutter_html.Display.inline,
                                      ),
                                      "code": flutter_html.Style(
                                        backgroundColor: Colors.grey[200],
                                        color: Colors.red,
                                      ),
                                      "ol": flutter_html.Style(
                                        margin: flutter_html.Margins.all(0),
                                        padding:
                                            flutter_html.HtmlPaddings.all(0),
                                      ),
                                      "ol li": flutter_html.Style(
                                        display:
                                            flutter_html.Display.inlineBlock,
                                      ),
                                      "ul": flutter_html.Style(
                                        display:
                                            flutter_html.Display.inlineBlock,
                                        padding:
                                            flutter_html.HtmlPaddings.symmetric(
                                                horizontal: 10),
                                        margin: flutter_html.Margins.all(0),
                                      ),
                                      ".code-block": flutter_html.Style(
                                          padding:
                                              flutter_html.HtmlPaddings.all(10),
                                          backgroundColor: Colors.grey[200],
                                          color: Colors.black,
                                          width: flutter_html.Width(150)),
                                      ".code-block code": flutter_html.Style(
                                          color: Colors.black)
                                    },
                                  ),
                                ),
                                if (groupFiles!.length == 1)
                                  singleFile.buildSingleFile(
                                      groupFiles[0], context, platform),
                                if (groupFiles.length > 2)
                                  mulitFile.buildMultipleFiles(
                                      groupFiles, platform, context),
                                const SizedBox(
                                  height: 16,
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: groupMessageThreadList.length,
                                  itemBuilder: (context, index) {
                                    String message =
                                        groupMessageThreadList[index]
                                            .groupthreadmsg
                                            .toString();

                                    String senderName =
                                        groupMessageThreadList[index]
                                            .name
                                            .toString();

                                    String dateTime =
                                        groupMessageThreadList[index]
                                            .created_at
                                            .toString();

                                    DateTime time =
                                        DateTime.parse(dateTime).toLocal();
                                    String threadCreateAt =
                                        DateFormat('MMM d, yyyy hh:mm a')
                                            .format(time);
                                    List<dynamic>? threadFiles = [];
                                    threadFiles = groupMessageThreadList[index]
                                        .fileUrls
                                        .where((files) => files != null)
                                        .toList();

                                    return Container(
                                      padding: const EdgeInsets.only(top: 10),
                                      width: MediaQuery.of(context).size.width *
                                          0.9,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                height: 50,
                                                width: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.amber,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: FittedBox(
                                                  alignment: Alignment.center,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            3.0),
                                                    child: Text(
                                                      senderName
                                                          .toUpperCase()
                                                          .characters
                                                          .first,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
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
                                                  color: Colors.grey.shade300,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          topRight: Radius
                                                              .circular(10),
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  10),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  10))),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      senderName,
                                                      style: const TextStyle(
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.7,
                                                      child: flutter_html.Html(
                                                        data: message,
                                                        style: {
                                                          ".bq": flutter_html
                                                              .Style(
                                                            border: const Border(
                                                                left: BorderSide(
                                                                    color: Colors
                                                                        .grey,
                                                                    width:
                                                                        5.0)),
                                                            padding: flutter_html
                                                                    .HtmlPaddings
                                                                .only(left: 10),
                                                          ),
                                                          "blockquote":
                                                              flutter_html
                                                                  .Style(
                                                            display:
                                                                flutter_html
                                                                    .Display
                                                                    .inline,
                                                          ),
                                                          "code": flutter_html
                                                              .Style(
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[200],
                                                            color: Colors.red,
                                                          ),
                                                          "ol": flutter_html
                                                              .Style(
                                                            margin: flutter_html
                                                                .Margins.all(0),
                                                            padding: flutter_html
                                                                    .HtmlPaddings
                                                                .all(0),
                                                          ),
                                                          "ol li": flutter_html
                                                              .Style(
                                                            display: flutter_html
                                                                .Display
                                                                .inlineBlock,
                                                          ),
                                                          "ul": flutter_html
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
                                                                .Margins.all(0),
                                                          ),
                                                          ".code-block": flutter_html.Style(
                                                              padding: flutter_html
                                                                      .HtmlPaddings
                                                                  .all(10),
                                                              backgroundColor:
                                                                  Colors.grey[
                                                                      200],
                                                              color:
                                                                  Colors.black,
                                                              width:
                                                                  flutter_html
                                                                      .Width(
                                                                          150)),
                                                          ".code-block code":
                                                              flutter_html.Style(
                                                                  color: Colors
                                                                      .black)
                                                        },
                                                      ),
                                                    ),
                                                    if (threadFiles!.length ==
                                                        1)
                                                      singleFile
                                                          .buildSingleFile(
                                                              threadFiles[0],
                                                              context,
                                                              platform),
                                                    if (threadFiles.length > 1)
                                                      mulitFile
                                                          .buildMultipleFiles(
                                                              threadFiles,
                                                              platform,
                                                              context),
                                                    Text(
                                                      threadCreateAt,
                                                      style: const TextStyle(
                                                          fontSize: 10),
                                                    ),
                                                    const SizedBox(),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                        style: TextButton.styleFrom(
                                            shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(8)),
                                                side: BorderSide(
                                                    color: Colors.white,
                                                    width: 5))),
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      GpThreadMessage(
                                                          channelID:
                                                              directGroupList[
                                                                      index]
                                                                  .channelId,
                                                          channelStatus:
                                                              directGroupList[
                                                                      index]
                                                                  .channelStatus,
                                                          channelName:
                                                              directGroupList[
                                                                      index]
                                                                  .channelName,
                                                          messageID:
                                                              directGroupList[
                                                                      index]
                                                                  .id,
                                                          message: groupMessage,
                                                          name: name,
                                                          time: directmsgTime,
                                                          fname: name)));
                                        },
                                        child: const Text(
                                          "reply",
                                          style: TextStyle(color: Colors.black),
                                        ))
                                  ],
                                ),
                                const SizedBox(),
                                Text(
                                  directmsgTime,
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
          },
        ),
      ),
    );
  }
}
