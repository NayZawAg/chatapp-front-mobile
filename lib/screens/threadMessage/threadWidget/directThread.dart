import 'package:dio/dio.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_frontend/model/dataInsert/thread_lists.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/threadMessages/thread_message_service.dart';

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
            itemCount: ThreadStore.thread!.d_thread!.length,
            itemBuilder: (context, index) {
              var snapshot = ThreadStore.thread;
              if (snapshot!.d_thread!.isEmpty) {
                return const ProgressionBar(
                  imageName: 'dataSending.json',
                  height: 200,
                  size: 200,
                );
              } else {
                List dStar = snapshot.directMsgstar!.toList();
                bool star = dStar.contains(snapshot.d_thread![index].id);
                String directThread =
                    snapshot.d_thread![index].directthreadmsg.toString();
                String directThreadName =
                    snapshot!.d_thread![index].name.toString();
                List<String> initials = directThreadName.split(" ").map((e) => e.substring(0, 1)).toList();
            String user_name = initials.join("");
                String directThreadTime =
                    snapshot!.d_thread![index].created_at.toString();
                DateTime time = DateTime.parse(directThreadTime).toLocal();
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
                                padding: const EdgeInsets.all(3.0),
                                child: Text(
                                 user_name.toUpperCase(),
                                  style: const  TextStyle(
                                  fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                         const   SizedBox(height: 5)
                        ],
                      ),
                     const  SizedBox(width: 5),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius:const  BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10))),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(directThreadName,style: TextStyle(fontSize: 17,fontWeight: FontWeight.bold),),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.5,
                                    child: Text(directThread,
                                        style: const TextStyle(fontSize: 15)),
                                  ),
                                  Text(
                                    createdAt,
                                    style: const  TextStyle(fontSize: 10),
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
              }
            }),
      ),
    );
  }
}
