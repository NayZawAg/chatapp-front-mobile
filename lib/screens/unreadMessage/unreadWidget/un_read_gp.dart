import 'package:dio/dio.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/services/unreadMessages/unread_message_services.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/model/dataInsert/unread_list.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;

class UnReadDirectGroup extends StatefulWidget {
  const UnReadDirectGroup({Key? key}) : super(key: key);

  @override
  State<UnReadDirectGroup> createState() => _UnReadDirectGpState();
}

class _UnReadDirectGpState extends State<UnReadDirectGroup> {
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
        body: ListView.builder(
          itemCount: snapshot!.unreadGpMsg!.length,
          itemBuilder: (context, index) {
            final groupMsgId = snapshot!.unreadGpMsg![index].id;
            final tUserChannelIds = snapshot!.t_user_channel_ids!.toList();
            String name = snapshot!.unreadGpMsg![index].name.toString();
            List<String> initials =
                name.split(" ").map((e) => e.substring(0, 1)).toList();
            String gp_name = initials.join("");
            String channelName =
                snapshot!.unreadGpMsg![index].channel_name.toString();
            String groupMessage =
                snapshot!.unreadGpMsg![index].groupmsg.toString();
            String gp_message_t =
                snapshot!.unreadGpMsg![index].created_at.toString();
            DateTime time = DateTime.parse(gp_message_t).toLocal();
            String createdAt = DateFormat('MMM d, yyyy hh:mm a').format(time);
            bool shouldDisplay = false;
            for (var tUserChannelId in tUserChannelIds) {
              if (int.parse(tUserChannelId) == groupMsgId) {
                shouldDisplay = true;
              }
            }
            if (shouldDisplay) {
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
                                gp_name.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 25, fontWeight: FontWeight.bold),
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
                        child: Row(
                          children: [
                            Column(
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
                                  // child: Text(groupMessage,
                                  //     style: const TextStyle(fontSize: 15)),
                                  child: flutter_html.Html(
                                    data: groupMessage,
                                    style: {
                                      "blockquote": flutter_html.Style(
                                        border: const Border(
                                            left: BorderSide(
                                                color: Colors.grey,
                                                width: 5.0)),
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
                                        display:
                                            flutter_html.Display.inlineBlock,
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
                                Text(
                                  createdAt,
                                  style: TextStyle(fontSize: 10),
                                )
                              ],
                            ),
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
          },
        ));
  }
}
