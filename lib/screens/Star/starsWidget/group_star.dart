import 'package:dio/dio.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/dataInsert/star_list.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_frontend/services/starlistsService/star_list.service.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';



class GroupStarWidget extends StatefulWidget {
  const GroupStarWidget({Key? key}) : super(key: key);

  @override
  State<GroupStarWidget> createState() => _GroupStarState();
}

class _GroupStarState extends State<GroupStarWidget> {
  final _starListService = StarListsService(Dio(BaseOptions(headers: {'Content-Type': 'application/json', 'Accept': 'application/json'})));

  int userId = SessionStore.sessionData!.currentUser!.id!.toInt();

  late Future<void> refreshFuture;

  @override
  void initState() {
    super.initState();
    refreshFuture = _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      var token = await getToken();
      var data = await _starListService.getAllStarList(userId, token!);
      if (mounted) {
        setState(() {
          StarListStore.starList = data;
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
        body: LiquidPullToRefresh(
      onRefresh: _refresh,
      color: Colors.blue.shade100,
      animSpeedFactor: 200,
      showChildOpacityTransition: true,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: StarListStore.starList!.groupStar!.length,
              itemBuilder: (context, index) {
                var snapshot = StarListStore.starList;
                String name = snapshot!.groupStar![index].name.toString();
                 List<String> initials = name.split(" ").map((e) => e.substring(0, 1)).toList();
                String gp_name = initials.join("");
                String groupmsg =
                    snapshot.groupStar![index].groupmsg.toString();
                String channelName =
                    snapshot.groupStar![index].channelName.toString();
                String dateFormat =
                    snapshot.groupStar![index].createdAt.toString();
                DateTime dateTime = DateTime.parse(dateFormat).toLocal();
                String time =
                    DateFormat('MMM d, yyyy hh:mm a').format(dateTime);

                return Container(
                padding: EdgeInsets.only(top: 10),
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
                              child: Text(gp_name.toUpperCase(),
                              style:  const TextStyle(fontWeight: FontWeight.bold),),
                            ),
                          ),
                     
                      ),
                      const  SizedBox( height: 5)
                      ],
                    
                    ),SizedBox(width: 5),
                    Container(
                      width: MediaQuery.of(context).size.width*0.7,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: const  BorderRadius.only(
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
                              style: const TextStyle(fontSize: 17,fontWeight: FontWeight.bold),
                              ),
                               Container(
                                width: MediaQuery.of(context).size.width*0.5,
                                 child: Text(groupmsg,
                                    style: const TextStyle(fontSize: 15)),
                               ),
                                  Text(time,style:  const TextStyle(fontSize: 10),)
                             
                            ],
                           ),
                      ),
                      
                    )
                  ],
                ),
              );
                // ListTile(
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
                //     channelName,
                //    style: const TextStyle(fontSize: 20)
                //   ),
                //   subtitle:
                //       Text(groupmsg, style: const TextStyle(fontSize: 15)),
                //   trailing: Text(
                //     time,
                //     style: const TextStyle(fontSize: 10),
                //   ),
                // );
              },
            ),
          ),
        ],
      ),
    ));
  }
}
