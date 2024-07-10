import 'package:dio/dio.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/dataInsert/star_list.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_frontend/services/starlistsService/star_list.service.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;

class DirectStars extends StatefulWidget {
  const DirectStars({Key? key}) : super(key: key);

  @override
  State<DirectStars> createState() => _DirectStarsState();
}

class _DirectStarsState extends State<DirectStars> {
  late Future<void> refreshFuture;
  final _starListService = StarListsService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  int userId = SessionStore.sessionData!.currentUser!.id!.toInt();

  @override
  void initState() {
    super.initState();
    refreshFuture = _fetchData();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations here
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      var token = await getToken();
      var data = await _starListService.getAllStarList(userId, token!);
      if (mounted) {
        // Check if the widget is still mounted before calling setState
        setState(() {
          StarListStore.starList = data;
        });
      }
    } catch (e) {
      // Handle errors here
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
          itemCount: StarListStore.starList?.directStar?.length ?? 0,
          itemBuilder: (context, index) {
            final starList = StarListStore.starList!;
            final star = starList.directStar![index];
            String name = star.name.toString();
            List<String> initials =
                name.split(" ").map((e) => e.substring(0, 1)).toList();
            String ds_name = initials.join("");
            String directmsg = star.directmsg.toString();
            String dateFormat = star.createdAt.toString();
            DateTime dateTime = DateTime.parse(dateFormat).toLocal();
            String time = DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
            // String time = DateTImeFormatter.convertJapanToMyanmarTime(times);
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
                              ds_name.toUpperCase(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
                            name,
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            // child: Text(directmsg,
                            //     style: const TextStyle(fontSize: 15)),
                            child: flutter_html.Html(
                              data: directmsg,
                              style: {
                                "blockquote": flutter_html.Style(
                                  border: const Border(
                                      left: BorderSide(
                                          color: Colors.grey, width: 5.0)),
                                  margin: flutter_html.Margins.all(0),
                                  padding:
                                      flutter_html.HtmlPaddings.only(left: 10),
                                ),
                                "ol": flutter_html.Style(
                                  margin: flutter_html.Margins.symmetric(
                                      horizontal: 10),
                                  padding: flutter_html.HtmlPaddings.symmetric(
                                      horizontal: 10),
                                ),
                                "ul": flutter_html.Style(
                                  display: flutter_html.Display.inlineBlock,
                                  padding: flutter_html.HtmlPaddings.symmetric(
                                      horizontal: 10),
                                  margin: flutter_html.Margins.all(0),
                                ),
                                "pre": flutter_html.Style(
                                  backgroundColor: Colors.grey[200],
                                  padding: flutter_html.HtmlPaddings.symmetric(
                                      horizontal: 10, vertical: 5),
                                ),
                                "code": flutter_html.Style(
                                  display: flutter_html.Display.inlineBlock,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.red,
                                  padding: flutter_html.HtmlPaddings.symmetric(
                                      horizontal: 10, vertical: 5),
                                )
                              },
                            ),
                          ),
                          Text(
                            time,
                            style: const TextStyle(fontSize: 10),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
            // return ListTile(
            //   leading: Container(
            //     height: 50,
            //     width: 50,
            //     color: Colors.amber,
            //     child: Center(
            //       child: Text(
            //         name.characters.first.toUpperCase(),
            //         style: const TextStyle(
            //           fontSize: 30,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     ),
            //   ),
            //   title: Text(
            //     directmsg,
            //    style: const TextStyle(fontSize: 20),
            //   ),
            //   subtitle: Text(
            //     time,
            //     style: const TextStyle(fontSize: 10),
            //   ),
            // );
          },
        ),
      ),
    );
  }
}
