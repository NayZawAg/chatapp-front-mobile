import 'package:dio/dio.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/dataInsert/unread_list.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/unreadMessages/unread_message_services.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;

class UnReadDirectThread extends StatefulWidget {
  const UnReadDirectThread({Key? key}) : super(key: key);

  @override
  State<UnReadDirectThread> createState() => _UnReadDirectThreadState();
}

class _UnReadDirectThreadState extends State<UnReadDirectThread> {
  late Future<void> refreshFuture;
  var snapshot = UnreadStore.unreadMsg;

  @override
  void initState() {
    super.initState();
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
              itemCount: snapshot!.unreadThreads!.length,
              itemBuilder: (context, index) {
                String directThreadName =
                    snapshot!.unreadThreads![index].name.toString();
                List<String> initials = directThreadName
                    .split(" ")
                    .map((e) => e.substring(0, 1))
                    .toList();
                String thread_name = initials.join("");
                String directMessage =
                    snapshot!.unreadThreads![index].directthreadmsg.toString();
                String directMessageTime =
                    snapshot!.unreadThreads![index].created_at.toString();
                DateTime time = DateTime.parse(directMessageTime).toLocal();
                String createdAt =
                    DateFormat('MMM d, yyyy hh:mm a').format(time);
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
                                padding: const EdgeInsets.all(1.0),
                                child: Text(
                                  thread_name.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5)
                        ],
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
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
                                directThreadName,
                                style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.5,
                                // child: Text(directMessage,
                                //     style: const TextStyle(fontSize: 15)),
                                child: flutter_html.Html(
                                  data: directMessage,
                                  style: {
                                    "blockquote": flutter_html.Style(
                                      border: const Border(
                                          left: BorderSide(
                                              color: Colors.grey, width: 5.0)),
                                      margin: flutter_html.Margins.all(0),
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
                                      display: flutter_html.Display.inlineBlock,
                                      padding:
                                          flutter_html.HtmlPaddings.symmetric(
                                              horizontal: 10),
                                      margin: flutter_html.Margins.all(0),
                                    ),
                                    "pre": flutter_html.Style(
                                      backgroundColor: Colors.grey[200],
                                      padding:
                                          flutter_html.HtmlPaddings.symmetric(
                                              horizontal: 10, vertical: 5),
                                    ),
                                    "code": flutter_html.Style(
                                      display: flutter_html.Display.inlineBlock,
                                      backgroundColor: Colors.grey[300],
                                      color: Colors.red,
                                      padding:
                                          flutter_html.HtmlPaddings.symmetric(
                                              horizontal: 10, vertical: 5),
                                    )
                                  },
                                ),
                              ),
                              Text(
                                createdAt,
                                style: const TextStyle(fontSize: 10),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                );
              }),
        ));
  }
}
