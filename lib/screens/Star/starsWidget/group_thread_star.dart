import 'package:dio/dio.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/dataInsert/star_list.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_frontend/services/starlistsService/star_list.service.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';


class GroupThreadStar extends StatefulWidget {
  const GroupThreadStar({super.key});

  @override
  State<GroupThreadStar> createState() => _GroupThreadStarState();
}

class _GroupThreadStarState extends State<GroupThreadStar> {
  final _starListService = StarListsService(Dio(BaseOptions(headers: {'Content-Type': 'application/json', 'Accept': 'application/json'})));

  // ignore: unused_field
  late Future<void> _refreshFuture;

  int userId = SessionStore.sessionData!.currentUser!.id!.toInt();
  

  @override
  void initState() {
    super.initState();
    _refreshFuture = _fetchData();
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
      animSpeedFactor: 100,
      showChildOpacityTransition: true,
      child: Column(children: [
        Expanded(
          child: ListView.builder(
            itemCount: StarListStore.starList!.groupStarThread!.length,
            itemBuilder: (context, index) {
              var snapshot = StarListStore.starList;
              String name = snapshot!.groupStarThread![index].name.toString();
             List<String> initials = name.split(" ").map((e) => e.substring(0, 1)).toList();
            String gpthread_name = initials.join("");
              String groupthreadmsg =
                  snapshot.groupStarThread![index].groupthreadmsg.toString();
              String channelName =
                  snapshot.groupStarThread![index].channelName.toString();
              String dateFormat =
                  snapshot.groupStarThread![index].createdAt.toString();
              DateTime dateTime = DateTime.parse(dateFormat);
              String time = DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
                          // String time = DateTImeFormatter.convertJapanToMyanmarTime(times);

              return Container(
                padding:  const EdgeInsets.only(top: 10),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Container(
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
                              child: Text(gpthread_name.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),),
                            ),
                          ),
                      
                      ),
                      const  SizedBox( height: 5)
                      ],
                    
                    ),const SizedBox(width: 5),
                    Container(
                      width: MediaQuery.of(context).size.width*0.7,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: const BorderRadius.only(
                                                topRight: Radius.circular(10),
                                                bottomLeft: Radius.circular(10),
                                                bottomRight:
                                                    Radius.circular(10))

                      ),
                      child:  Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(channelName,
                              style:const TextStyle(fontSize: 17,fontWeight: FontWeight.bold),
                              ),
                               Container(
                                width: MediaQuery.of(context).size.width*0.5,
                                 child: Text(groupthreadmsg,
                                    style: const TextStyle(fontSize: 15)),
                               ),
                                  Text(time,style: const TextStyle(fontSize: 10),)
                             
                            ],
                           ),
                      ),
                      
                    )
                  ],
                ),
              );
              // Align(
              //   alignment: Alignment.topCenter,
              //   child: ListTile(
              //     leading: Container(
              //       height: 50,
              //       width: 50,
              //       color: Colors.amber,
              //       child: Center(
              //         child: Text(
              //           name.characters.first.toUpperCase(),
              //           style: TextStyle(
              //             fontSize: 30,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //       ),
              //     ),
              //     title: Text(
              //       channelName,
              //        style: const TextStyle(fontSize: 20),
              //     ),
              //     subtitle: Text(
              //       groupthreadmsg,
              //       style: const TextStyle(fontSize: 15),
              //     ),
              //     trailing: Text(
              //       time,
              //       style: const TextStyle(fontSize: 10),
              //     ),
              //   ),
              // );
            },
          ),
        ),
      ]),
    ));
  }
}
