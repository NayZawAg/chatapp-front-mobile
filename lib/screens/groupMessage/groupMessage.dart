import 'dart:async';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/groupMessage.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/screens/Login/login_form.dart';
import 'package:flutter_frontend/screens/groupMessage/groupThread.dart';
import 'package:flutter_frontend/screens/groupMessage/Drawer/drawer.dart';
import 'package:flutter_frontend/services/groupMessageService/group_message_service.dart';
import 'package:flutter_frontend/services/groupMessageService/gropMessage/groupMessage_Services.dart';
// ignore_for_file: prefer_const_constructors, must_be_immutable


// ignore: depend_on_referenced_packages

enum SampleItem { itemOne, itemTwo, itemThree }

class GroupMessage extends StatefulWidget {
  final channelID, channelName, workspace_id, memberName;
  final channelStatus;
  final member;
  GroupMessage(
      {super.key,
      this.channelID,
      this.channelStatus,
      this.channelName,
      this.member,
      this.workspace_id,
      this.memberName});

  @override
  State<GroupMessage> createState() => _GroupMessage();
}

class _GroupMessage extends State<GroupMessage> with RouteAware {
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  final groupMessageService = GroupMessageServices(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
    late ScrollController _scrollController;
  final StreamController<groupMessageData> _control =
      StreamController<groupMessageData>();
  final StreamController<groupMessageData> _control1 =
      StreamController<groupMessageData>();
  String? groupMessageName;
  late Timer _timer;
  bool isloading = false;
  bool isButtom = false;
  @override
  void initState() {
    super.initState();
     _scrollController = ScrollController();
     _scrollToBottom();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
     _scrollController.dispose();
    _startTimer();
  }

  RetrieveGroupMessage data = RetrieveGroupMessage();
  void _startTimer() async {
    if (!isloading) {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        try {
          final token = await getToken();

          groupMessageData gpMessage =
              await groupMessageService.getAllGpMsg(widget.channelID, token!);

          setState(() {
            data = gpMessage.retrieveGroupMessage!; // Update data here
          });
          _control.add(gpMessage);
          _control1.add(gpMessage);
           WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } catch (e) {
          print(e);
          
        }
      });
    }
  }
  
  void _scrollToBottom() {
    if (isButtom) return; 
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendGroupMessageData(
      String groupMessage, int channelID, List<String> mentionName) async {
    final token = await getToken();
    try {
      await groupMessageService.sendGroupMsgData({
        "s_channel_id": channelID,
        "message": groupMessage,
        "mention_name": mentionName
      }, token!);
    } catch (e) {
      rethrow;
    }
  }

  groupMessageData? _getUserDetails;

  Future<void> fetchUserDetailsUpdate() async {
    _getUserDetails = await fetchAlbum(widget.channelID);

    setState(() {
      memberCount = _getUserDetails!.retrievehome!.mUsers!.length;
      //  Member
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  String? channelName;
  int? memberCount;

  @override
  Widget build(BuildContext context) {
    int? groupMessageID;
    int? channelID;

    if (data.mChannelUsers == null || data.create_admin == null) {
      return ProgressionBar(
        imageName: 'dataSending.json',
        height: 200,
        size: 200,
      );
    } else {
      if(SessionStore.sessionData!.currentUser!.memberStatus == true){
        return Scaffold(
        resizeToAvoidBottomInset: true,
        key: _scaffoldKey,
        backgroundColor: kPriamrybackground,
        drawer: Drawer(
            child: DrawerPage(
                channelId: widget.channelID,
                channelName: widget.channelName,
                channelStatus: widget.channelStatus,
                memberCount: memberCount,
                memberName: widget.memberName,
                member: data.mChannelUsers,
                adminID: data.create_admin!)),
        appBar: AppBar(
          backgroundColor: navColor,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
                setState() {
              isloading = !isloading;
            }

            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const Nav()));
            },
          ),
          title: Row(
            children: [
              Container(
                child: widget.channelStatus
                    ? Icon(
                        Icons.tag,
                        color: Colors.white,
                      )
                    : Icon(
                        Icons.lock,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(
                width: 10,
              ),
              Column(
                children: [
                  GestureDetector(
                      onTap: () {
                        _openDrawer();
                      },
                      child: Text(
                        widget.channelName,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      )),
                ],
              ),
            ],
          ),
        ),
      
        body: GestureDetector(
          onTap: (){
            setState(() {
              isButtom = true;
            });
          },
          child: Column(
            children:[ Expanded(
              child: StreamBuilder<groupMessageData?>(
                stream: _control.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError || !snapshot.hasData) {
                    return ProgressionBar(
                      imageName: 'dataSending.json',
                      height: 200,
                      size: 200,
                    );
                  } else  {
                    groupMessageData groupMessageList = snapshot.data!;
                    int groupMessageLength = groupMessageList
                        .retrieveGroupMessage!.tGroupMessages!.length
                        .toInt();
                      
                    return ListView.builder(
                      
                      shrinkWrap: true,
                      controller: _scrollController,
                      itemCount: groupMessageLength,
                      itemBuilder: (BuildContext context, int index) {
                        SampleItem? selectedItem;
                    
                        List tgroupStarMessageIds = groupMessageList
                            .retrieveGroupMessage!.tGroupStarMsgids!
                            .toList();
                            
                    
                        bool isStarred = tgroupStarMessageIds.contains(
                            groupMessageList.retrieveGroupMessage!
                                .tGroupMessages![index].id);
                    
                        int? count = groupMessageList
                            .retrieveGroupMessage!
                            .tGroupMessages![index]
                            .count;
                        int messageID = groupMessageList
                            .retrieveGroupMessage!
                            .tGroupMessages![index]
                            .id!
                            .toInt();
                        String message = groupMessageList
                            .retrieveGroupMessage!
                            .tGroupMessages![index]
                            .groupmsg
                            .toString();
                        int currentUser = SessionStore.sessionData!.currentUser!.id!.toInt();
                        int  sendUserId = groupMessageList.retrieveGroupMessage!.tGroupMessages![index].sendUserId!.toInt();
                        List<TGroupMessages>? name = groupMessageList
                            .retrieveGroupMessage!.tGroupMessages;
                       String gp_name = name![index].name.toString();
                        List<String> initials = gp_name.split(" ").map((e) => e.substring(0, 1)).toList();
                        String groupName = initials.join("");
                        String time = groupMessageList
                            .retrieveGroupMessage!
                            .tGroupMessages![index]
                            .createdAt
                            .toString();
                        DateTime date = DateTime.parse(time).toLocal();
                        String created_at =
                            DateFormat('MMM d, yyyy hh:mm a')
                                .format(date);

                    
                        return SingleChildScrollView(
                          child: Container(
                            padding: EdgeInsets.only(top: 10),
                            width:
                                MediaQuery.of(context).size.width * 0.9,
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
                                                BorderRadius.circular(
                                                    25)),
                                      
                                            child: FittedBox(
                                              alignment: Alignment.center,
                                              child: Padding(
                                                padding: const EdgeInsets.all(3.0),
                                                child: Text(
                                                                                          groupName
                                                  .toUpperCase(),
                                                                                          style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  
                                                  ),
                                                                                        ),
                                              ),
                                            )
                                      
                                        ),
                                    SizedBox(
                                      height: 22,
                                    )
                                  ],
                                ),
                                SizedBox(width: 5),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width *
                                          0.78,
                                  decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(10),
                                          bottomLeft: Radius.circular(10),
                                          bottomRight:
                                              Radius.circular(10))
                                              ),
                                  child: ListTile(
                                  
                                    title: Container(
                                      margin: EdgeInsets.only(left: 0),
                                      child: Column(
                                        children: [
                                          ListTile(
                          
                                            title: SelectableText(
                                              message,
                                              style:
                                                  TextStyle(fontSize: 18),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(created_at,
                                                    style: TextStyle(
                                                        fontSize: 10)),
                                                Text(
                                                  'Thread : $count',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: PopupMenuButton<SampleItem>(
                                      initialValue: selectedItem,
                                      onSelected: (SampleItem item) {
                                        setState(() {
                                          selectedItem = item;
                                        });
                                      },
                                      itemBuilder: (BuildContext
                                              context) =>
                                          <PopupMenuEntry<SampleItem>>[
                                        PopupMenuItem<SampleItem>(
                                          value: SampleItem.itemOne,
                                          onTap: () async {
                                            setState(() {
                                              groupMessageID =
                                                  groupMessageList
                                                      .retrieveGroupMessage!
                                                      .tGroupMessages![
                                                          index]
                                                      .id!
                                                      .toInt();
                                              channelID = groupMessageList
                                                  .retrieveGroupMessage!
                                                  .sChannel!
                                                  .id!
                                                  .toInt();
                                            });
                                            if (tgroupStarMessageIds
                                                .contains(
                                                    groupMessageID)) {
                                              try {
                                                await deleteGroupStarMessage(
                                                    groupMessageID!,
                                                    channelID!);
                                              } catch (e) {
                                                rethrow;
                                              }
                                            } else {
                                              await getMessageStar(
                                                  groupMessageID!,
                                                  channelID!);
                                            }
                                          },
                                          child: ListTile(
                                              leading: isStarred ?? true
                                                  ? const Icon(Icons.star,
                                                      color:
                                                          Colors.yellow)
                                                  : const Icon(
                                                      Icons.star_outline,
                                                      color:
                                                          Colors.black),
                                              title: Text("Star")),
                                        ),
                                        PopupMenuItem<SampleItem>(
                                            value: SampleItem.itemTwo,
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          GpThreadMessage(
                                                            channelID: widget
                                                                .channelID,
                                                            channelStatus:
                                                                widget
                                                                    .channelStatus,
                                                            channelName:
                                                                widget
                                                                    .channelName,
                                                            messageID:
                                                                messageID,
                                                            message:
                                                                message,
                                                            name: name[
                                                                    index]
                                                                .name
                                                                .toString(),
                                                            time:
                                                                created_at,
                                                            fname: name[
                                                                    index]
                                                                .name
                                                                .toString()
                                                          )));
                                            },
                                            child: ListTile(
                                              leading: Icon(Icons.reply),
                                              title: Text('Threads'),
                                            )),
                                        PopupMenuItem<SampleItem>(
                                          value: SampleItem.itemThree,
                                          onTap: currentUser == sendUserId?  () async {
                                            setState(() {
                                              groupMessageID =
                                                  groupMessageList
                                                      .retrieveGroupMessage!
                                                      .tGroupMessages![
                                                          index]
                                                      .id!
                                                      .toInt();
                                              channelID = groupMessageList
                                                  .retrieveGroupMessage!
                                                  .sChannel!
                                                  .id!
                                                  .toInt();
                                            });
                                            await deleteGroupMessage(
                                                groupMessageID!,
                                                channelID!);
                                          } : (){
                                            ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Cannot Delete the Message'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
          
                                          },
                                          child: ListTile(
                                            leading: Icon(Icons.delete,color: Colors.red,),
                                            title: Text('delete'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ), 
            const SizedBox(height: 10,),
            Padding(
            padding: const EdgeInsets.only(left: 10,right: 10),
            child: StreamBuilder(
                stream: _control1.stream,
                builder: ((context, snapshot) {
                  
                    List<Map<String, Object?>> mention =
                        data.mChannelUsers!.map((e) {
                      return {'display': e.name, 'name': e.name};
                    }).toList();
                    
                    return FlutterMentions(
                      key: key,
                      suggestionPosition: SuggestionPosition.Top,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                          hintText: 'send messages',
                          suffixIcon: GestureDetector(
                              onTap: () {
                                
                                String name = key.currentState!.controller!.text
                                    .trimRight();
                                int? channelId = widget.channelID;
            
                                String mentionName = " ";
                                List<String> userSearchItems = [];
                                mention.forEach((data) {
                                  if (name.contains('@${data['display']}')) {
                                    mentionName = '@${data['display']}';
            
                                    userSearchItems.add(mentionName);
                                  }
                                });
            
                                sendGroupMessageData(
                                    name, channelId!, userSearchItems);
                                key.currentState!.controller!.text = " ";
                              },
                              child: Icon(Icons.telegram,
                                  color: Colors.blue, size: 35))),
                      mentions: [
                        Mention(
                            trigger: '@',
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                            data: mention,
                            matchAll: false,
                            suggestionBuilder: (data) {
                              return Container(
                                color: Colors.grey.shade200,
                                padding: EdgeInsets.all(10.0),
                                child: Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 20.0,
                                    ),
                                    Column(
                                      children: <Widget>[
                                        //  Text(data['display']),
                                        Text('@${data['display']}'),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            }),
                      ],
                    );
                  
                })),
          ),
            ],
          ),
        ),
        
        
      );
    
      }
      else {
         return CustomLogOut();
      }
    }
  }
}
