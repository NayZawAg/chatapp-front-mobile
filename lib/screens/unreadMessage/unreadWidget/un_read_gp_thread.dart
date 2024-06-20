import 'package:dio/dio.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/services/unreadMessages/unread_message_services.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/model/dataInsert/unread_list.dart';

class UnReadGroupThread extends StatefulWidget {
  const UnReadGroupThread({Key? key}) : super(key: key);

  @override
  State<UnReadGroupThread> createState() => _UnReadGroupThreadState();
}

class _UnReadGroupThreadState extends State<UnReadGroupThread> {
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
            itemCount: snapshot!.unreadGpThreads!.length,
            itemBuilder: (context, index) {
              final groupThreadId = snapshot!.unreadGpThreads![index].id;
              String name =
                  snapshot!.unreadGpThreads![index].name.toString();
               List<String> initials = name.split(" ").map((e) => e.substring(0, 1)).toList();
              String gp_name = initials.join("");
              String channelName = snapshot!
                  .unreadGpThreads![index].channel_name
                  .toString();
              String groupThreadMessage = snapshot!
                  .unreadGpThreads![index].groupthreadmsg
                  .toString();
              String gp_thread_message_t = snapshot!
                  .unreadGpThreads![index].created_at
                  .toString();
              DateTime time =
                  DateTime.parse(gp_thread_message_t).toLocal();
              String createdAt =
                  DateFormat('MMM d, yyyy hh:mm a').format(time);
              bool shouldDisplay = false;
              for(var tUserChannelThreadId in t_user_channel_thread_ids){
                if(int.parse(tUserChannelThreadId) == groupThreadId){
                  shouldDisplay = true;
                }
              }
              if(shouldDisplay){
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
              
                                    child:FittedBox(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.all(1.0),
                                        child: Text(gp_name.toUpperCase(),
                                        style: const TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
                                      ),
                                    ),                                
                                  ),
                                  const SizedBox( height: 22)
                                  ],                            
                                ),
                              SizedBox(width: 5),
                              Container(
                                width: MediaQuery.of(context).size.width*0.7,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(10),
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10)
                                  ),        
                                ),
                                child:  Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(channelName,
                                          style:TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
                                          ),
                                          Container(
                                            width: MediaQuery.of(context).size.width*0.5,
                                            child: Text(groupThreadMessage,
                                              style: const TextStyle(fontSize: 15)),                              
                                            ),                     
                                          Text(createdAt,style: TextStyle(fontSize: 10),)                   
                                  ],
                                ),
                              ],
                            ),
                          ),        
                        )
                      ],
                    ),
                  );
              }
              else{
                return Container();
              }
            }));
  }
}
