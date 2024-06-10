import 'package:dio/dio.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/const/date_time.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_frontend/model/dataInsert/thread_lists.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/threadMessages/thread_message_service.dart';

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

  @override
  void initState() {
    super.initState();
    refrshFuture = _fetchData();
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
        // Check if the widget is still mounted before calling setState
        setState(() {
          ThreadStore.thread = data;
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
          itemCount: ThreadStore.thread!.groupThread!.length,
          itemBuilder: (context, index) {
            var snapshot = ThreadStore.thread;
            List groupThreadStar = snapshot!.groupThreadStar!.toList();
            bool star =
                groupThreadStar.contains(snapshot.groupThread![index].id);
            String groupThread =
                snapshot.groupThread![index].groupthreadmsg.toString();
            String channelName = snapshot.groupThread![index].channelName.toString();
            String groupThreadName =
                snapshot.groupThread![index].name.toString();
            List<String> initials = groupThreadName.split(" ").map((e) => e.substring(0, 1)).toList();
            String user_name = initials.join("");
            String groupThreadTime =
                snapshot.groupThread![index].created_at.toString();
            DateTime time = DateTime.parse(groupThreadTime).toLocal();
            String created_at = DateFormat('MMM d, yyyy hh:mm a').format(time);
            // String created_at =
            //     DateTImeFormatter.convertJapanToMyanmarTime(
            //         created_ats);
            return Container(
              padding: EdgeInsets.only(top: 10),
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
                              user_name.toUpperCase(),
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(channelName,style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold),),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: Text(groupThread,
                                    style: const TextStyle(fontSize: 15)),
                              ),
                              Text(
                                created_at,
                                style: const TextStyle(fontSize: 10),
                              )
                            ],
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            child: star
                                ? const Icon(
                                    Icons.star,
                                    color: Colors.yellow,
                                  )
                                : null,
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
