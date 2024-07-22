import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/dotenv.dart';
import '../groupMessage/groupMessage.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/model/SessionState.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/screens/home/homeDrawer.dart';
import 'package:flutter_frontend/screens/mChannel/m_channel_create.dart';
import 'package:flutter_frontend/screens/memverinvite/member_invite.dart';
import 'package:flutter_frontend/screens/directMessage/direct_message.dart';
import 'package:flutter_frontend/services/userservice/mainpage/mian_page.dart';
import 'package:flutter_frontend/services/mChannelService/m_channel_services.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';

class WorkHome extends StatefulWidget {
  const WorkHome({Key? key}) : super(key: key);

  @override
  State<WorkHome> createState() => _WorkHomeState();
}

class _WorkHomeState extends State<WorkHome> {
  int? joinId;
  DateTime? currentBackPressTime;

  final _apiService = MainPageService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  bool isreading = false;
  late Future<void> refreshFuture;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    startFecting();
    getMainPage();
  }

  @override
  void dispose() {
    super.dispose();
  }

  AuthController controller = AuthController();
  int? directMessageUserID;
  String? directMessageUserName;
  bool _showJoinButton = true;

  Future<String?> getToken() async {
    return await controller.getToken();
  }

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  Future<void> getMainPage() async {
    var token = await getToken();
    final response = await MainPageService(Dio((BaseOptions(headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    })))).mainPage(token!);
    if (mounted) {
      setState(() {
        SessionStore.sessionData = response;
      });
    }
  }

  void startFecting() async {
    _refresh();
  }

  Future<void> _refresh() async {
    await getMainPage();
  }

  @override
  Widget build(BuildContext context) {
    if (SessionStore.sessionData == null) {
      return const ProgressionBar(
        imageName: 'waiting.json',
        color: Colors.white,
        height: 500,
        size: 500,
      );
    } else {
      var data = SessionStore.sessionData;
      String currentEmail = data!.currentUser!.email.toString();
      String currentName = data.currentUser!.name.toString();
      int currentUserId = data.currentUser!.id!.toInt();
      String? currentUserProfileImage = data.currentUser?.imageUrl;

      if (currentUserProfileImage != null && !kIsWeb) {
        currentUserProfileImage = MinioToIP.replaceMinioWithIP(
            currentUserProfileImage, ipAddressForMinio);
      }

      String workspace = data.mWorkspace!.workspaceName.toString();
      List<String> initials =
          workspace.split(" ").map((e) => e.substring(0, 1)).toList();
      String w_name = initials.join("");
      String currentWs = data.mWorkspace!.workspaceName!.toString();
      int channelLength = data.mPChannels!.length;
      int channelLengths = data.mChannels!.length;
      int workSpaceUserLength = data.mUsers!.length;
      int allunread = data.allUnreadCount!.toInt();

      if (SessionStore.sessionData!.currentUser!.memberStatus == true) {
        return WillPopScope(
          onWillPop: () async {
            if (currentBackPressTime == null ||
                DateTime.now().difference(currentBackPressTime!) >
                    const Duration(seconds: 2)) {
              currentBackPressTime = DateTime.now();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Press back again to exit')));
              return false;
            } else {
              return true;
            }
          },
          child: Scaffold(
            key: _scaffoldKey,
            drawer: Drawer(
              child: HomeDrawer(
                useremail: currentEmail,
                username: currentName,
                workspacename: currentWs,
              ),
            ),
            backgroundColor: kPriamrybackground,
            appBar: AppBar(
              backgroundColor: navColor,
              leading: GestureDetector(
                onTap: _openDrawer,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[300],
                    ),
                    child: Center(
                      child: currentUserProfileImage == null ||
                              currentUserProfileImage.isEmpty
                          ? const Icon(Icons.person)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                currentUserProfileImage,
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              title: Column(
                children: [
                  Text(
                    currentName,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              actions: [
                allunread == 0
                    ? Container()
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            const Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 30,
                            ),
                            Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                      color: Colors.yellow,
                                      borderRadius: BorderRadius.circular(7)),
                                  child: Center(
                                      child: Text(
                                    "${allunread}",
                                    style: const TextStyle(
                                        color: navColor, fontSize: 10),
                                  )),
                                ))
                          ],
                        ),
                      )
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    ExpansionTile(
                      shape: const Border(bottom: BorderSide.none),
                      initiallyExpanded: true,
                      title: const Text(
                        'Channels',
                        style: TextStyle(color: kPrimaryTextColor),
                      ),
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 300.0),
                          child: ListView.builder(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: channelLengths + channelLength,
                            itemBuilder: (context, index) {
                              if (index < channelLengths) {
                                final channel = data.mChannels![index];
                                final messageCount = data
                                    .mChannels![index].messageCount!
                                    .toInt();
                                List<MUsers>? userName = data.mUsers;
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GroupMessage(
                                          channelID: channel.id,
                                          channelStatus: channel.channelStatus,
                                          channelName: channel.channelName,
                                          workspace_id: data.mWorkspace!.id,
                                          memberName: userName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ListTile(
                                    leading: channel.channelStatus!
                                        ? const Icon(Icons.tag)
                                        : const Icon(Icons.lock),
                                    title: Row(
                                      children: [
                                        Text(
                                          channel.channelName ?? '',
                                          style: const TextStyle(
                                              color: kPrimaryTextColor),
                                        ),
                                        const SizedBox(
                                          width: 15,
                                        ),
                                        messageCount == 0
                                            ? Container()
                                            : Container(
                                                height: 15,
                                                width: 15,
                                                decoration: BoxDecoration(
                                                  color: Colors.yellow,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.5),
                                                ),
                                                child: Center(
                                                    child: Text(
                                                  "${messageCount}",
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                )),
                                              )
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                final channel =
                                    data.mPChannels![index - channelLengths];

                                bool channelExists = data.mChannels!
                                    .any((m) => m.id == channel.id);

                                if (channelExists) {
                                  return const SizedBox.shrink();
                                } else {
                                  return GestureDetector(
                                    onTap: () {},
                                    child: ListTile(
                                      leading: channel.channelStatus!
                                          ? const Icon(Icons.tag)
                                          : const Icon(Icons.lock),
                                      title: Text(
                                        channel.channelName ?? '',
                                        style: const TextStyle(
                                            color: kPrimaryTextColor),
                                      ),
                                      trailing: _showJoinButton
                                          ? TextButton(
                                              style: ButtonStyle(
                                                  side:
                                                      MaterialStateProperty.all(
                                                const BorderSide(
                                                    width: 1,
                                                    color: Colors.black),
                                              )),
                                              onPressed: () {
                                                // Perform API call to join channel
                                                MChannelServices()
                                                    .channelJoin(currentUserId,
                                                        channel.id!.toInt())
                                                    .then((_) {
                                                  // If API call is successful, hide the button
                                                  setState(() {
                                                    _showJoinButton = false;
                                                  });
                                                }).catchError((error) {
                                                  // Handle error if API call fails
                                                });
                                              },
                                              child: const Text('Join ME'),
                                            )
                                          : null, // If _showJoinButton is false, don't show the button
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MChannelCreate(),
                              ),
                            );
                          },
                          child: const ListTile(
                            leading: Icon(Icons.add),
                            title: Text("Add Channel!"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ExpansionTile(
                      initiallyExpanded: true,
                      title: const Text(
                        "Direct Messages",
                        style: TextStyle(color: kPrimaryTextColor),
                      ),
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300.0),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: workSpaceUserLength,
                            itemBuilder: (context, index) {
                              bool? activeStatus =
                                  data.mUsers![index].activeStatus;
                              String userName =
                                  data.mUsers![index].name.toString();
                              List<String> initials = userName
                                  .split(" ")
                                  .map((e) => e.substring(0, 1))
                                  .toList();
                              String dm_name = initials.join("");
                              int userIds = data.mUsers![index].id!.toInt();
                              int count1 = data.directMsgcounts![index].toInt();
                              String? profileImage =
                                  data.mUsers![index].imageUrl;
                              if (profileImage != null && !kIsWeb) {
                                profileImage = MinioToIP.replaceMinioWithIP(
                                    profileImage, ipAddressForMinio);
                              }
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DirectMessageWidget(
                                        user_status: activeStatus,
                                        userId: userIds,
                                        receiverName: userName,
                                        activeStatus: activeStatus,
                                        profileImage: profileImage,
                                      ),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  leading: Stack(children: [
                                    Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: Center(
                                        child: profileImage == null ||
                                                profileImage.isEmpty
                                            ? const Icon(Icons.person)
                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.network(
                                                  profileImage,
                                                  fit: BoxFit.cover,
                                                  width: 40,
                                                  height: 40,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                        right: 0,
                                        top: 0,
                                        child: count1 == 0
                                            ? Container()
                                            : Container(
                                                height: 15,
                                                width: 15,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.5),
                                                    color: Colors.yellow,
                                                    border: Border.all(
                                                        color: Colors.white,
                                                        width: 1)),
                                                child: Center(
                                                    child: Text(
                                                  "$count1",
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                )))),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        height: 10,
                                        width: 10,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(7),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                          color: activeStatus == true
                                              ? Colors.green
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ]),
                                  title: currentUserId == userIds
                                      ? RichText(
                                          text: TextSpan(
                                            text: userName + '  ',
                                            style: const TextStyle(
                                                color: kPrimaryTextColor),
                                            children: [
                                              TextSpan(
                                                  text: '(You)',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        )
                                      : Text(
                                          userName,
                                          style: const TextStyle(
                                              color: kPrimaryTextColor),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MemberInvitation(),
                              ),
                            );
                          },
                          child: const ListTile(
                            leading: Icon(Icons.add),
                            title: Text("Add Member"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        return CustomLogOut();
      }
    }
  }
}
