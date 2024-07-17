import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/dotenv.dart';
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
    refreshFuture = _fetchData();
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

              return Container(
                padding: const EdgeInsets.only(top: 10),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[300],
                              ),
                              child: Center(
                                child: directProfileName == null ||
                                        directProfileName.isEmpty
                                    ? const Icon(Icons.person)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          directProfileName,
                                          fit: BoxFit.cover,
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
                                    dmName,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (otherUser == "")
                                              ? "自分のみ"
                                              : "$otherUser さんとあなた",
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ]),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Container(
                                      child: Column(
                                    children: [
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.5,
                                        // child: Text(directThread,
                                        //     style: const TextStyle(fontSize: 15)),
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
                                                            horizontal: 10,
                                                            vertical: 5),
                                                    margin:
                                                        flutter_html.Margins
                                                            .symmetric(
                                                                vertical: 7)),
                                            ".highlight": flutter_html.Style(
                                              display: flutter_html
                                                  .Display.inlineBlock,
                                              backgroundColor: Colors.grey[200],
                                              color: Colors.red,
                                              padding: flutter_html.HtmlPaddings
                                                  .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                            ),
                                            "blockquote": flutter_html.Style(
                                              border: const Border(
                                                  left: BorderSide(
                                                      color: Colors.grey,
                                                      width: 5.0)),
                                              margin: flutter_html.Margins
                                                  .symmetric(vertical: 10.0),
                                              padding: flutter_html.HtmlPaddings
                                                  .only(left: 10),
                                            ),
                                            "ol": flutter_html.Style(
                                              margin: flutter_html.Margins
                                                  .symmetric(horizontal: 10),
                                              padding: flutter_html.HtmlPaddings
                                                  .symmetric(horizontal: 10),
                                            ),
                                            "ul": flutter_html.Style(
                                              display: flutter_html
                                                  .Display.inlineBlock,
                                              padding: flutter_html.HtmlPaddings
                                                  .symmetric(horizontal: 10),
                                              margin:
                                                  flutter_html.Margins.all(0),
                                            ),
                                            "pre": flutter_html.Style(
                                              backgroundColor: Colors.grey[300],
                                              padding: flutter_html.HtmlPaddings
                                                  .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                            ),
                                            "code": flutter_html.Style(
                                              display: flutter_html
                                                  .Display.inlineBlock,
                                              backgroundColor: Colors.grey[300],
                                              color: Colors.red,
                                              padding: flutter_html.HtmlPaddings
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
                                  const SizedBox(height: 8),
                                  const SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: directThreadList.length,
                                    itemBuilder: (context, index) {
                                      String message = directThreadList[index]
                                          .directthreadmsg
                                          .toString();
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

                                      return Container(
                                        padding: const EdgeInsets.only(top: 10),
                                        width:
                                            MediaQuery.of(context).size.width *
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
                                                        BorderRadius.circular(
                                                            10),
                                                    color: Colors.grey[300],
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
                                                            child:
                                                                Image.network(
                                                              threadProfileName,
                                                              fit: BoxFit.cover,
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
                                                    color: Colors.grey.shade300,
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                            topRight:
                                                                Radius.circular(
                                                                    10),
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
                                                        child:
                                                            flutter_html.Html(
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
                                                                  Colors.grey[
                                                                      200],
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
                                                                  .only(
                                                                      left: 10),
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
                                                                      .Margins
                                                                  .all(0),
                                                            ),
                                                            "pre": flutter_html
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
                                                            "code": flutter_html
                                                                .Style(
                                                              display: flutter_html
                                                                  .Display
                                                                  .inlineBlock,
                                                              backgroundColor:
                                                                  Colors.grey[
                                                                      300],
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
                                                      if (threadFiles != null &&
                                                          threadFiles
                                                              .isNotEmpty) ...[
                                                        if (threadFiles
                                                                    .length ==
                                                                1 &&
                                                            threadFiles
                                                                .isNotEmpty)
                                                          singleFile
                                                              .buildSingleFile(
                                                                  threadFiles[
                                                                      0],
                                                                  context,
                                                                  platform,
                                                                  threadFileName
                                                                          ?.first ??
                                                                      ''),
                                                        if (threadFiles.length >
                                                                2 &&
                                                            threadFiles
                                                                .isNotEmpty)
                                                          mulitFile
                                                              .buildMultipleFiles(
                                                                  threadFiles,
                                                                  platform,
                                                                  context,
                                                                  threadFileName ??
                                                                      []),
                                                      ],
                                                      const SizedBox(
                                                        height: 8,
                                                      ),
                                                      const SizedBox(
                                                        height: 8,
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
