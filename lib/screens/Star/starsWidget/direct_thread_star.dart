import 'package:dio/dio.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/dataInsert/star_list.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_frontend/services/starlistsService/star_list.service.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';

class DirectThreadStars extends StatefulWidget {
  const DirectThreadStars({super.key});

  @override
  State<DirectThreadStars> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<DirectThreadStars> {
  final _starListService = StarListsService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  // ignore: unused_field
  late Future<void> _refreshFuture;

  int userId = SessionStore.sessionData!.currentUser!.id!.toInt();
  var snapshot = StarListStore.starList;

  @override
  void initState() {
    super.initState();
    _refreshFuture = _fetchData();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations here
    super.dispose();
  }

  Future<void> _fetchData() async {
    var token = await getToken();
    var data = await _starListService.getAllStarList(userId, token!);

    if (mounted) {
      setState(() {
        snapshot = data;
      });
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
          child: Column(children: [
            Expanded(
              child: ListView.builder(
                itemCount: snapshot!.directStarThread!.length,
                itemBuilder: (context, index) {
                  String name =
                      snapshot!.directStarThread![index].name.toString();
                  List<String> initials = name.split(" ").map((e) => e.substring(0, 1)).toList();
                  String dt_name = initials.join("");
                  String directthreadmsg = snapshot!
                      .directStarThread![index].directthreadmsg
                      .toString();
                  String dateFormat =
                      snapshot!.directStarThread![index].createdAt.toString();
                  DateTime dateTime = DateTime.parse(dateFormat).toLocal();
                  String time =
                      DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
                  //  String time = DateTImeFormatter.convertJapanToMyanmarTime(times);

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
                                     dt_name.toUpperCase(),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  child: Text(directthreadmsg,
                                      style: const TextStyle(fontSize: 15)),
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
                },
              ),
            ),
          ]),
        ));
  }
}
