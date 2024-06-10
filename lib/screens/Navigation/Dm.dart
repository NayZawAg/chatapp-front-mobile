import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/screens/directMessage/direct_message.dart';
import 'package:flutter_frontend/screens/memverinvite/member_invite.dart';
import 'package:flutter_frontend/model/SessionStore.dart';


class DirectMessage extends StatefulWidget {
  const DirectMessage({super.key});

  @override
  State<DirectMessage> createState() => _DirectMessageState();
}

class _DirectMessageState extends State<DirectMessage> {
  @override
  Widget build(BuildContext context) {
    int? directMessageUserID;
    String? directMessageUserName;
    int workSpaceUserLength = SessionStore.sessionData!.mUsers!.length;
   
    return
            
          
           Scaffold(
              backgroundColor: kPriamrybackground,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: navColor,
                title: const Text("Direct Messages",
                style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                actions: [
                  
                  IconButton(onPressed: (){
                     Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MemberInvitation()),
                          );
                  }, icon: const  Tooltip(
                    message: 'add member',
                    child: Icon(Icons.add,color: Colors.white,)))
                ],
              ),
              body: Container(
                  child: Column(
                    children: [
                     
                        SingleChildScrollView(
                          child: Container(
                            height: MediaQuery.of(context).size.height*0.6,
                            child: ListView.builder(
                              itemCount: workSpaceUserLength,
                              itemBuilder: (context, index) {
                                int count1 = SessionStore.sessionData!.directMsgcounts![index].toInt();
                                int userIds = SessionStore.sessionData!.mUsers![index].id!.toInt();
                                String userName = SessionStore.sessionData!.mUsers![index].name.toString();
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GestureDetector(
                                    onTap: () {
                                            setState(() {
                                                directMessageUserID = userIds;
                                                directMessageUserName =
                                                    userName;
                                              });

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      DirectMessageWidget(
                                                    userId:
                                                        directMessageUserID!,
                                                    receiverName:
                                                        directMessageUserName!,
                                                  ),
                                                ),
                                              );
                                    },
                                    child: ListTile(
                                     leading: Stack(
                                                  children: [
                                                  Container(
                                                    height: 50,
                                                    width: 50,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade600,
                                                      borderRadius:
                                                          BorderRadius.circular(25),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        userName.characters.first
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                            fontSize: 30,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                                color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    right: 0,
                                                   top:0,
                                                    child:count1 == 0 ? Container() : Container(
                                                      height: 15,
                                                      width: 18,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(7),
                                                        color: Colors.yellow,
                                                        border: Border.all(width: 1,color: Colors.white)
                                                      ),
                                                      child: Center(child: Text("$count1",style: TextStyle(fontWeight: FontWeight.bold),))))
                                                  ]
                                                ),
                                      title: Text(
                                        userName,
                                        style:
                                            const TextStyle(color: kPrimaryTextColor),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      
                      
                    ],
                  ),
                ),
              
            );
          }        
  }
  

