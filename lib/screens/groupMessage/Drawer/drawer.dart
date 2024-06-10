import 'package:flutter/material.dart';
import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/services/mChannelService/m_channel_services.dart';
import 'package:flutter_frontend/services/groupMessageService/group_message_service.dart';
import 'package:flutter_svg/svg.dart';

enum ChannelType { public, private }

class DrawerPage extends StatefulWidget {
  final dynamic channelName,
      memberCount,
      channelStatus,
      channelId,
      memberName,
      adminID;
  final member;

  DrawerPage(
      {super.key,
      this.channelName,
      this.adminID,
      this.memberCount,
      this.channelStatus,
      this.member,
      this.channelId,
      this.memberName});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

String workSpaceName =
    SessionStore.sessionData!.mWorkspace!.workspaceName.toString();

    

class _DrawerPageState extends State<DrawerPage> {
  bool light = false;
  final TextEditingController _channelNameController = TextEditingController();
  ChannelType? currentOption;
  @override
  void initState() {
    super.initState();
    setState(() {
      currentOption =
          widget.channelStatus ? ChannelType.public : ChannelType.private;
    });
  }

  @override
  Widget build(BuildContext context) {
    // List<dynamic> notAdded1 = widget.memberName;
    dynamic notAdded = [];
    widget.memberName.forEach((member) {
      if (!widget.member.map((e) => e.name).contains(member.name)) {
        notAdded.add(member);
      }
    });
    int? currentID = SessionStore.sessionData!.currentUser!.id;
    int? channelAdmin = widget.adminID[0]!.userid!;
    int? memberNo = notAdded.length.toInt();
    return Container(
      color: Color(0xFFcedef0),
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            padding: EdgeInsets.all(10),
            color: Colors.black12,
            child: Center(
              child: ListTile(
                leading: widget.channelStatus
                    ? const Icon(
                        Icons.tag,
                        size: 50,
                        color: Color(0xFF2F3C7E),
                      )
                    : const Icon(Icons.lock,
                        size: 40, color: Color(0xFF2F3C7E)),
                title: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    widget.channelName,
                    style: const TextStyle(
                        fontSize: 30,
                        color: Color(0xFF2F3C7E),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                subtitle: Text(
                  '${widget.member.toList().length} : member',
                  style: const TextStyle(color: Color(0xFF2F3C7E)),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // see membert
                GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: SingleChildScrollView(
                              child: Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                child: ListView.builder(
                                    itemCount: widget.member.toList().length,
                                    itemBuilder: (context, index) {
                                      bool? memberActive =
                                          widget.member[index].activeStatus;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            left: 10, top: 7, right: 10),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                              color: Colors.grey.shade400,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: ListTile(
                                              leading: Stack(
                                                children: [
                                                  Container(
                                                      height: 50,
                                                      width: 50,
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(25),
                                                      ),
                                                      child: Center(
                                                          child: Text(
                                                        widget
                                                            .member[index].name
                                                            .toString()
                                                            .characters
                                                            .first
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                            fontSize: 25),
                                                      ))),
                                                  Positioned(
                                                      right: 0,
                                                      bottom: 0,
                                                      child:
                                                          memberActive == true
                                                              ? Container(
                                                                  height: 14,
                                                                  width: 14,
                                                                  decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              7),
                                                                      border: Border.all(
                                                                          color: Colors
                                                                              .white,
                                                                          width:
                                                                              1),
                                                                      color: Colors
                                                                          .green),
                                                                )
                                                              : Container())
                                                ],
                                              ),
                                              title: Text(widget
                                                  .member[index].name
                                                  .toString()),
                                              trailing: currentID !=
                                                          widget.member[index]
                                                              .id &&
                                                      channelAdmin !=
                                                          widget.member[index]
                                                              .id &&
                                                      currentID == channelAdmin
                                                  ? IconButton(
                                                      onPressed: () {
                                                        var response =
                                                            deleteMember(
                                                                widget
                                                                    .member[
                                                                        index]
                                                                    .id,
                                                                widget
                                                                    .channelId);
                                                        response.whenComplete(
                                                            () => Navigator.pop(
                                                                context));
                                                      },
                                                      icon: const Icon(Icons
                                                          .logout_outlined),
                                                    )
                                                  : null),
                                        ),
                                      );
                                    }),
                              ),
                            )));
                  },
                  child: const ListTile(
                    leading: Icon(
                      Icons.people_alt_outlined,
                      color: Color(0xFF2F3C7E),
                    ),
                    title: Text(
                      'See Member',
                      style: TextStyle(
                          color: Color(0xFF2F3C7E),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                //add button
                GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    const Text(
                                      'Member Add',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    memberNo == 0
                                        ? SizedBox(
                                           height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.5,
                                          
                                                child: SvgPicture.asset("assets/images/null1.svg",color: navColor,),
                                        )
                                        : SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.4,
                                            child: ListView.builder(
                                                itemCount:
                                                    notAdded.length.toInt(),
                                                itemBuilder: (context, index) {
                                                  int userID = notAdded[index]
                                                      .id
                                                      .toInt();
                                                  return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 10,
                                                              right: 10,
                                                              top: 8),
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    10),
                                                            decoration: BoxDecoration(
                                                                color: Colors
                                                                    .grey
                                                                    .shade400,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10)),
                                                            child: ListTile(
                                                                leading:
                                                                    Container(
                                                                        height:
                                                                            50,
                                                                        width:
                                                                            50,
                                                                        decoration: BoxDecoration(
                                                                            color: Colors
                                                                                .amber,
                                                                            borderRadius: BorderRadius.circular(
                                                                                25)),
                                                                        child:
                                                                            Center(
                                                                                child:
                                                                                    Text(
                                                                          notAdded[index]
                                                                              .name
                                                                              .toString()
                                                                              .characters
                                                                              .first
                                                                              .toUpperCase(),
                                                                          style: const TextStyle(
                                                                              color: Colors.black,
                                                                              fontSize: 25),
                                                                        ))),
                                                                title: Text(notAdded[
                                                                        index]
                                                                    .name
                                                                    .toString()),
                                                                trailing:
                                                                    IconButton(
                                                                        onPressed:
                                                                            () {
                                                                          var response = MChannelServices().channelJoin(
                                                                              userID,
                                                                              widget.channelId);

                                                                          response
                                                                              .whenComplete(() {
                                                                            Navigator.pop(context);
                                                                          });
                                                                        },
                                                                        icon:
                                                                            const Icon(
                                                                          Icons
                                                                              .add,
                                                                        ))),
                                                          ),
                                                        ],
                                                      ));
                                                })),
                                  ],
                                ),
                              ),
                            ));
                  },
                  child: const ListTile(
                      leading: Icon(Icons.add, color: Color(0xFF2F3C7E)),
                      title: Text('Member Add',
                          style: TextStyle(
                              color: Color(0xFF2F3C7E),
                              fontWeight: FontWeight.bold))),
                ),

                //Leave Channel
                channelAdmin == currentID
                    ? const ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: Colors.grey,
                        ),
                        title: Text(
                          'Leave Channel',
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold),
                        ))
                    : GestureDetector(
                        onTap: () {
                          var response =
                              deleteMember(currentID!, widget.channelId);
                          response.whenComplete(() => Navigator.push(context,
                              MaterialPageRoute(builder: (context) => Nav())));
                        },
                        child: const ListTile(
                            leading: Icon(
                              Icons.logout,
                              color: Color(0xFF2F3C7E),
                            ),
                            title: Text(
                              'Leave Channel',
                              style: TextStyle(
                                  color: Color(0xFF2F3C7E),
                                  fontWeight: FontWeight.bold),
                            )),
                      ),
                // Edit Button
                channelAdmin == currentID
                    ? GestureDetector(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return StatefulBuilder(
                                    builder: ((context, setState) {
                                  return AlertDialog(
                                    title: const Text("Edit Channel"),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          const SizedBox(
                                            height: 15,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: TextFormField(
                                              controller:
                                                  _channelNameController,
                                              keyboardType: TextInputType.name,
                                              textInputAction:
                                                  TextInputAction.next,
                                              cursorColor: Colors
                                                  .blue, // Change to your desired color
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.grey[
                                                    200], // Change to your desired background color
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0), // Adjust border radius as needed
                                                  borderSide: const BorderSide(
                                                      width:
                                                          1), // No side border
                                                ),
                                                hintText:
                                                    "${widget.channelName}",
                                                prefixIcon:
                                                    const Icon(Icons.edit),
                                              ),
                                              validator: (value) {
                                                if (value!.length > 15) {
                                                  return 'Channel name too long!';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              RadioListTile<ChannelType>(
                                                title: const Text(
                                                    'Public - Anyone'),
                                                value: ChannelType.public,
                                                groupValue: currentOption,
                                                onChanged:
                                                    (ChannelType? value) {
                                                  setState(() {
                                                    currentOption = value!;
                                                  });
                                                },
                                              ),
                                              RadioListTile<ChannelType>(
                                                title: const Text('Private'),
                                                value: ChannelType.private,
                                                groupValue: currentOption,
                                                onChanged:
                                                    (ChannelType? value) {
                                                  setState(() {
                                                    currentOption = value!;
                                                  });
                                                },
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 30,
                                                    right: 30,
                                                    top: 5,
                                                    bottom: 5),
                                                child: TextButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.blue.shade300,
                                                      // Change to your desired background color
                                                    ),
                                                    onPressed: () {
                                                      editChannel(
                                                          widget.channelId);
                                                      print(
                                                          _channelNameController
                                                              .text.length);
                                                    },
                                                    child: const Center(
                                                      child: ListTile(
                                                        leading: Icon(
                                                          Icons.edit,
                                                          color: Colors.white,
                                                        ),
                                                        title: Text(
                                                          "Edit",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                    )),
                                              ),
                                              const SizedBox(
                                                height: 15,
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }));
                              });
                        },
                        child: const ListTile(
                            leading: Icon(Icons.edit, color: Color(0xFF2F3C7E)),
                            title: Text('Edit Channel',
                                style: TextStyle(
                                    color: Color(0xFF2F3C7E),
                                    fontWeight: FontWeight.bold))),
                      )
                    : const ListTile(
                        leading: Icon(
                          Icons.edit,
                          color: Colors.grey,
                        ),
                        title: Text('Edit Channel',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ),
          const SizedBox(
            height: 50,
          ),
          //delete channel
          channelAdmin == currentID
              ? GestureDetector(
                  onTap: () {
                    deleteChannel(widget.channelId)
                        .then((value) => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Nav(),

                            )));
                             ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Channel delete successfully'),
                        backgroundColor: Colors.green,
                      ),
      );
                  },
                  child: const ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete Channel',
                        style: TextStyle(
                            color: Color(0xFF2F3C7E),
                            fontWeight: FontWeight.bold)),
                  ),
                )
              : const ListTile(
                  leading: Icon(Icons.delete, color: Colors.grey),
                  title: Text('Delete Channel',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                )
        ],
      ),
    );
  }

  void editChannel(int channelId) async {
    try {
      final String channelName = _channelNameController.text.isEmpty
          ? widget.channelName
          : _channelNameController.text.trim();
      final bool channelStatus =
          currentOption == ChannelType.private ? false : true;
      final int workspace_id =
          SessionStore.sessionData!.mWorkspace!.id!.toInt();
      await updateChannel(channelId, channelStatus, channelName, workspace_id);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Channel edit successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // ignore: use_build_context_synchronously
      Navigator.push(context, MaterialPageRoute(builder: (context) => Nav()));
    } catch (e) {
      print('Error creating channel: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to edit channel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
