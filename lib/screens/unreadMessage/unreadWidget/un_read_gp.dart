import 'package:flutter_frontend/constants.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/model/dataInsert/unread_list.dart';

class UnReadDirectGroup extends StatefulWidget {
  const UnReadDirectGroup({Key? key}) : super(key: key);

  @override
  State<UnReadDirectGroup> createState() => _UnReadDirectGpState();
}

class _UnReadDirectGpState extends State<UnReadDirectGroup> {
  var snapshot = UnreadStore.unreadMsg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPriamrybackground,
        body: ListView.builder(
            itemCount: snapshot!.unreadGpMsg!.length,
            itemBuilder: (context, index) {
              String name =
                  snapshot!.unreadGpMsg![index].name.toString();
               List<String> initials = name.split(" ").map((e) => e.substring(0, 1)).toList();
              String gp_name = initials.join("");
              String channelName = snapshot!
                  .unreadGpMsg![index].channel_name
                  .toString();
              String groupMessage = snapshot!
                  .unreadGpMsg![index].groupmsg
                  .toString();
              String gp_message_t = snapshot!
                  .unreadGpMsg![index].created_at
                  .toString();
              DateTime time =
                  DateTime.parse(gp_message_t).toLocal();
              String createdAt =
                  DateFormat('MMM d, yyyy hh:mm a').format(time);
        
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
          
            child:FittedBox(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Text(gp_name.toUpperCase(),
                style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
              ),
            ),
          
        ),
        SizedBox( height: 22)
        ],
                            
                            ),SizedBox(width: 5),
                            Container(
        width: MediaQuery.of(context).size.width*0.7,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                  bottomRight:
                                      Radius.circular(10))
        
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
                      child: Text(groupMessage,
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
        
              // return Column(
              //   children: [
              //     ListTile(
              //       leading: Container(
              //           height: 40,
              //           width: 40,
              //           color: Colors.amber,
              //           child: Center(
              //               child: Text(
              //             name.characters.first,
              //             style: const TextStyle(
              //                 fontSize: 30,
              //                 fontWeight: FontWeight.bold),
              //           ))),
              //       title: Row(
              //         children: [
              //           Text(
              //             name,
              //             style: const TextStyle(
              //                 fontWeight: FontWeight.bold),
              //           ),
              //           const SizedBox(
              //             width: 20,
              //           ),
              //           Text(
              //             createdAt,
              //             style: const TextStyle(
              //                 fontSize: 10,
              //                 color:
              //                     Color.fromARGB(143, 0, 0, 0)),
              //           )
              //         ],
              //       ),
              //       subtitle: Text(groupMessage),
              //       trailing: Text("channel: $channelName"),
              //     ),
              //   ],
              // );
            }));
  }
}
