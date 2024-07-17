import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/screens/groupMessage/groupMessage.dart';
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
            List<dynamic>? groupFileName = [];
            groupFileName = directGroupList[index].fileName;

            int channelId = directGroupList[index].channelId!.toInt();

            String channelName = directGroupList[index].channelName.toString();
            bool? chaneelStatus = directGroupList[index].channelStatus;

            String? groupProfileImage = directGroupList[index].profileName;

            if (groupProfileImage != null && !kIsWeb) {
              groupProfileImage = MinioToIP.replaceMinioWithIP(
                  groupProfileImage, ipAddressForMinio);
            }

            bool? activeStatus;
            for (var user in SessionStore.sessionData!.mUsers!) {
              if (user.name == name) {
                activeStatus = user.activeStatus;
              }
            }

            int currentWorkSpaceId =
                SessionStore.sessionData!.mWorkspace!.id!.toInt();

            return Container(
              padding: const EdgeInsets.only(top: 5),
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10))),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(TextSpan(children: [
                                  WidgetSpan(
                                      child: GestureDetector(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GroupMessage(
                                            channelID: channelId,
                                            channelName: channelName,
                                            channelStatus: chaneelStatus,
                                            workspace_id: currentWorkSpaceId,
                                          ),
                                        )),
                                    child: Row(
                                      children: [
                                        Icon(chaneelStatus!
                                            ? Icons.tag
                                            : Icons.lock),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          channelName,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    ),
                                  ))
                                ])),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(30, 0, 0, 0),
                                  child: Text(result),
                                ),
                                const Divider(),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: flutter_html.Html(
                                    data: groupMessage,
                                    style: {
                                      ".ql-code-block": flutter_html.Style(
                                          backgroundColor: Colors.grey[200],
                                          padding: flutter_html.HtmlPaddings
                                              .symmetric(
                                                  horizontal: 10, vertical: 5),
                                          margin:
                                              flutter_html.Margins.symmetric(
                                                  vertical: 7)),
                                      ".highlight": flutter_html.Style(
                                        display:
                                            flutter_html.Display.inlineBlock,
                                        backgroundColor: Colors.grey[200],
                                        color: Colors.red,
                                        padding:
                                            flutter_html.HtmlPaddings.symmetric(
                                                horizontal: 10, vertical: 5),
                                      ),
                                      "blockquote": flutter_html.Style(
                                        border: const Border(
                                            left: BorderSide(
                                                color: Colors.grey,
                                                width: 5.0)),
                                        margin: flutter_html.Margins.symmetric(
                                            vertical: 10.0),
                                        padding: flutter_html.HtmlPaddings.only(
                                            left: 10),
                                      ),
                                      "ol": flutter_html.Style(
                                        margin: flutter_html.Margins.symmetric(
                                            horizontal: 10),
                                        padding:
                                            flutter_html.HtmlPaddings.symmetric(
                                                horizontal: 10),
                                      ),
                                      "ul": flutter_html.Style(
                                        display:
                                            flutter_html.Display.inlineBlock,
                                        padding:
                                            flutter_html.HtmlPaddings.symmetric(
                                                horizontal: 10),
                                        margin: flutter_html.Margins.all(0),
                                      ),
                                      "pre": flutter_html.Style(
                                        backgroundColor: Colors.grey[300],
                                        padding:
                                            flutter_html.HtmlPaddings.symmetric(
                                                horizontal: 10, vertical: 5),
                                      ),
                                      "code": flutter_html.Style(
                                        display:
                                            flutter_html.Display.inlineBlock,
                                        backgroundColor: Colors.grey[300],
                                        color: Colors.red,
                                        padding:
                                            flutter_html.HtmlPaddings.symmetric(
                                                horizontal: 10, vertical: 5),
                                      )
                                    },
                                  ),
                                ),
                                if (groupFiles!.length == 1)
                                  singleFile.buildSingleFile(
                                      groupFiles[0],
                                      context,
                                      platform,
                                      groupFileName?.first ?? ''),
                                if (groupFiles.length >= 2)
                                  mulitFile.buildMultipleFiles(groupFiles,
                                      platform, context, groupFileName ?? []),
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

                                    List<dynamic>? threadFileName = [];
                                    threadFileName =
                                        groupMessageThreadList[index].fileName;

                                    String? groupThreadProfileName =
                                        groupMessageThreadList[index]
                                            .profileName;

                                    if (groupThreadProfileName != null &&
                                        !kIsWeb) {
                                      groupThreadProfileName =
                                          MinioToIP.replaceMinioWithIP(
                                              groupThreadProfileName,
                                              ipAddressForMinio);
                                    }

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
                                                height: 40,
                                                width: 40,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Colors.grey[300],
                                                ),
                                                child: Center(
                                                  child: groupThreadProfileName ==
                                                              null ||
                                                          groupThreadProfileName
                                                              .isEmpty
                                                      ? const Icon(Icons.person)
                                                      : ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          child: Image.network(
                                                            groupThreadProfileName,
                                                            fit: BoxFit.cover,
                                                            width: 40,
                                                            height: 40,
                                                          ),
                                                        ),
                                                ),
                                              ),
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
                                                          ".ql-code-block": flutter_html.Style(
                                                              backgroundColor:
                                                                  Colors.grey[
                                                                      200],
                                                              padding: flutter_html
                                                                      .HtmlPaddings
                                                                  .symmetric(
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
                                                                Colors
                                                                    .grey[200],
                                                            color: Colors.red,
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
                                                                .only(left: 10),
                                                          ),
                                                          "ol": flutter_html
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
                                                          "pre": flutter_html
                                                              .Style(
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[300],
                                                            padding: flutter_html
                                                                    .HtmlPaddings
                                                                .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        5),
                                                          ),
                                                          "code": flutter_html
                                                              .Style(
                                                            display: flutter_html
                                                                .Display
                                                                .inlineBlock,
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[300],
                                                            color: Colors.red,
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
                                                    if (threadFiles!.length ==
                                                        1)
                                                      singleFile
                                                          .buildSingleFile(
                                                              threadFiles[0],
                                                              context,
                                                              platform,
                                                              threadFileName
                                                                      ?.first ??
                                                                  ''),
                                                    const SizedBox(
                                                      height: 3,
                                                    ),
                                                    if (threadFiles.length > 1)
                                                      mulitFile
                                                          .buildMultipleFiles(
                                                              threadFiles,
                                                              platform,
                                                              context,
                                                              threadFileName ??
                                                                  []),
                                                    const SizedBox(
                                                      height: 3,
                                                    ),
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
                                          ),
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
