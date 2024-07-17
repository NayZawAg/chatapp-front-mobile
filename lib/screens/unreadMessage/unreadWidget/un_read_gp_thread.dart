import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/services/unreadMessages/unread_message_services.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_frontend/model/dataInsert/unread_list.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;

class UnReadGroupThread extends StatefulWidget {
  const UnReadGroupThread({Key? key}) : super(key: key);

  @override
  State<UnReadGroupThread> createState() => _UnReadGroupThreadState();
}

class _UnReadGroupThreadState extends State<UnReadGroupThread> {
  late Future<void> refreshFuture;
  var snapshot = UnreadStore.unreadMsg;
  TargetPlatform? platform;
  BuildMulitFile mulitFile = BuildMulitFile();
  BuildSingleFile singleFile = BuildSingleFile();

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
    refreshFuture = _fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchData() async {
    int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
    int workspaceId = SessionStore.sessionData!.mWorkspace!.id!.toInt();
    try {
      var token = await AuthController().getToken();
      var unreadListStore = await UnreadMessageService(Dio(BaseOptions(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }))).getAllUnreadMsg(currentUserId, workspaceId, token!);
      setState(() {
        snapshot = unreadListStore;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refresh() async {
    await _fetchData();
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
              itemCount: snapshot!.unreadGpThreads!.length,
              itemBuilder: (context, index) {
                final groupThreadId = snapshot!.unreadGpThreads![index].id;
                final tUserChannelThreadIds =
                    snapshot!.t_user_channel_thread_ids!.toList();
                String name = snapshot!.unreadGpThreads![index].name.toString();
                List<String> initials =
                    name.split(" ").map((e) => e.substring(0, 1)).toList();
                String gp_name = initials.join("");
                String channelName =
                    snapshot!.unreadGpThreads![index].channel_name.toString();
                String groupThreadMessage =
                    snapshot!.unreadGpThreads![index].groupthreadmsg.toString();
                String gp_thread_message_t =
                    snapshot!.unreadGpThreads![index].created_at.toString();
                DateTime time = DateTime.parse(gp_thread_message_t).toLocal();
                String createdAt =
                    DateFormat('MMM d, yyyy hh:mm a').format(time);
                bool shouldDisplay = false;
                for (var tUserChannelThreadId in tUserChannelThreadIds) {
                  if (int.parse(tUserChannelThreadId) == groupThreadId) {
                    shouldDisplay = true;
                  }
                }

                List<dynamic>? files = [];
                List<dynamic>? fileName = [];

                files = snapshot!.unreadGpThreads![index].files;
                fileName = snapshot!.unreadGpThreads![index].fileNames;

                String? profileImage =
                    snapshot!.unreadGpThreads![index].profileImage;

                if (profileImage != null && !kIsWeb) {
                  profileImage = MinioToIP.replaceMinioWithIP(
                      profileImage, ipAddressForMinio);
                }
                if (shouldDisplay) {
                  return Container(
                    padding: const EdgeInsets.only(top: 10),
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Row(
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
                                child: profileImage == null ||
                                        profileImage.isEmpty
                                    ? const Icon(Icons.person)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          profileImage,
                                          fit: BoxFit.cover,
                                          width: 40,
                                          height: 40,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 22)
                          ],
                        ),
                        SizedBox(width: 5),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  channelName,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  // child: Text(groupThreadMessage,
                                  //     style: const TextStyle(fontSize: 15)),
                                  child: flutter_html.Html(
                                    data: groupThreadMessage,
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
                                files?.length == 1
                                    ? singleFile.buildSingleFile(
                                        files?.first ?? '',
                                        context,
                                        platform,
                                        fileName?.first ?? '')
                                    : mulitFile.buildMultipleFiles(files ?? [],
                                        platform, context, fileName ?? []),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  createdAt,
                                  style: TextStyle(fontSize: 10),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                } else {
                  return Container();
                }
              }),
        ));
  }
}
