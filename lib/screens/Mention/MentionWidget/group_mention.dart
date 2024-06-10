import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_frontend/model/dataInsert/mention_list.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/mentionlistsService/mention_list.service.dart';
// ignore: depend_on_referenced_packages

class GroupMessages extends StatefulWidget {
  const GroupMessages({super.key});

  @override
  State<GroupMessages> createState() => _GroupMessageState();
}

class _GroupMessageState extends State<GroupMessages> {
  final _mentionListService = MentionListService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  late Future<void> _refreshFuture;

  int userId = SessionStore.sessionData!.currentUser!.id!.toInt();
  var snapshot = MentionStore.mentionList;
  @override
  void initState() {
    super.initState();
    _refreshFuture = _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      var token = await getToken();
      var data = await _mentionListService.getAllMentionList(userId, token!);
      if (mounted) {
        setState(() {
          snapshot = data;
        });
      }
    } catch (e) {}
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
        body: SingleChildScrollView(
            child: Container(
                height: MediaQuery.of(context).size.height*0.7,
                child: LiquidPullToRefresh(
                  onRefresh: _refresh,
                  color: Colors.blue.shade100,
                  animSpeedFactor: 100,
                  showChildOpacityTransition: true,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: snapshot!.groupMessage!.length,
                          itemBuilder: (context, index) {
                            List gpThreadStar = snapshot!.groupStar!.toList();
                            bool star = gpThreadStar
                                .contains(snapshot!.groupMessage![index].id);
                            String dateFormat = snapshot!
                                .groupMessage![index].createdAt
                                .toString();
                            DateTime dateTime =
                                DateTime.parse(dateFormat).toLocal();
                            String time = DateFormat('MMM d, yyyy hh:mm a')
                                .format(dateTime);
                            String name =
                                snapshot!.groupMessage![index].name.toString();
                             List<String> initials = name.split(" ").map((e) => e.substring(0, 1)).toList();
                            String user_name = initials.join("");
                            String groupmsg = snapshot!
                                .groupMessage![index].groupmsg
                                .toString();
                            String channelName = snapshot!
                                .groupMessage![index].channelName
                                .toString();
                            return Container(
                              padding: const EdgeInsets.only(top: 10),
                              width: MediaQuery.of(context).size.width * 0.9,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
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
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                channelName,
                                                style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.5,
                                                child: Text(groupmsg,
                                                    style: const TextStyle(
                                                        fontSize: 15)),
                                              ),
                                              Text(
                                                time,
                                                style:
                                                    const TextStyle(fontSize: 10),
                                              ),
                                             
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
                          },
                        ),
                      ),
                    ],
                  ),
                ))));
  }
}
