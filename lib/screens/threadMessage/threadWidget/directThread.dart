import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/constants.dart';
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

              return Container(
                padding: const EdgeInsets.only(top: 10),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Row(
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
                                dmName.toUpperCase(),
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
                                dmName,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                  child: Column(
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.5,
                                    // child: Text(directThread,
                                    //     style: const TextStyle(fontSize: 15)),
                                    child: flutter_html.Html(
                                      data: dmMessage,
                                      style: {
                                        ".bq": flutter_html.Style(
                                          // backgroundColor: Colors.purple
                                          border: const Border(
                                              left: BorderSide(
                                                  color: Colors.grey,
                                                  width: 5.0)),
                                          padding:
                                              flutter_html.HtmlPaddings.only(
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
                                          padding: flutter_html.HtmlPaddings
                                              .symmetric(horizontal: 10),
                                          margin: flutter_html.Margins.all(0),
                                        ),
                                        ".code-block": flutter_html.Style(
                                            padding:
                                                flutter_html.HtmlPaddings.all(
                                                    10),
                                            backgroundColor: Colors.grey[200],
                                            color: Colors.black,
                                            width: flutter_html.Width(150)),
                                        ".code-block code": flutter_html.Style(
                                            color: Colors.black)
                                      },
                                    ),
                                  ),
                                  if (directFiles!.length == 1 &&
                                      directFiles.isNotEmpty)
                                    singleFile.buildSingleFile(
                                        directFiles[0], context, platform),
                                  if (directFiles.length > 2 &&
                                      directFiles.isNotEmpty)
                                    mulitFile.buildMultipleFiles(
                                        directFiles, platform, context),
                                ],
                              )),
                              const SizedBox(height: 8),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: directThreadList.length,
                                itemBuilder: (context, index) {
                                  String message = directThreadList[index]
                                      .directthreadmsg
                                      .toString();
                                  String senderName =
                                      directThreadList[index].name.toString();

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

                                  return Container(
                                    padding: const EdgeInsets.only(top: 10),
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
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
                                                      const EdgeInsets.all(3.0),
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
                                                        topRight:
                                                            Radius.circular(10),
                                                        bottomLeft:
                                                            Radius.circular(10),
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
                                                            0.5,
                                                    // child: Text(directThread,
                                                    //     style: const TextStyle(fontSize: 15)),
                                                    child: flutter_html.Html(
                                                      data: message,
                                                      style: {
                                                        ".bq":
                                                            flutter_html.Style(
                                                          // backgroundColor: Colors.purple
                                                          border: const Border(
                                                              left: BorderSide(
                                                                  color: Colors
                                                                      .grey,
                                                                  width: 5.0)),
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .only(left: 10),
                                                        ),
                                                        "blockquote":
                                                            flutter_html.Style(
                                                          display: flutter_html
                                                              .Display.inline,
                                                        ),
                                                        "code":
                                                            flutter_html.Style(
                                                          backgroundColor:
                                                              Colors.grey[200],
                                                          color: Colors.red,
                                                        ),
                                                        "ol":
                                                            flutter_html.Style(
                                                          margin: flutter_html
                                                              .Margins.all(0),
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .all(0),
                                                        ),
                                                        "ol li":
                                                            flutter_html.Style(
                                                          display: flutter_html
                                                              .Display
                                                              .inlineBlock,
                                                        ),
                                                        "ul":
                                                            flutter_html.Style(
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
                                                        ".code-block":
                                                            flutter_html.Style(
                                                                padding:
                                                                    flutter_html
                                                                            .HtmlPaddings
                                                                        .all(
                                                                            10),
                                                                backgroundColor:
                                                                    Colors.grey[
                                                                        200],
                                                                color: Colors
                                                                    .black,
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
                                                  if (threadFiles != null &&
                                                      threadFiles
                                                          .isNotEmpty) ...[
                                                    if (threadFiles.length ==
                                                            1 &&
                                                        threadFiles.isNotEmpty)
                                                      singleFile
                                                          .buildSingleFile(
                                                              threadFiles[0],
                                                              context,
                                                              platform),
                                                    if (threadFiles.length >
                                                            2 &&
                                                        threadFiles.isNotEmpty)
                                                      mulitFile
                                                          .buildMultipleFiles(
                                                              threadFiles,
                                                              platform,
                                                              context),
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
                                                    DirectMessageThreadWidget(
                                                        directMsgId:
                                                            directMsgId,
                                                        receiverId:
                                                            receiverId)));
                                      },
                                      child: const Text(
                                        "reply",
                                        style: TextStyle(color: Colors.black),
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
              );
            }
          },
        ),
      ),
    );
  }
}
