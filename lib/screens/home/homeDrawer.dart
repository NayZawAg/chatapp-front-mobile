import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/screens/profile/profile.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/screens/Login/login_form.dart';
import 'package:flutter_frontend/screens/userManage/usermanage.dart';
import 'package:flutter_frontend/screens/mChannel/m_channel_create.dart';
import 'package:flutter_frontend/screens/memverinvite/member_invite.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/userservice/api_controller_services.dart';
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

class HomeDrawer extends StatefulWidget {
  final workspacename, username, useremail;
  const HomeDrawer(
      {super.key, this.useremail, this.username, this.workspacename});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  Future<String?> getToken() async {
    return await AuthController().getToken();
  }

  final _apiService = LoginService(Dio());

  @override
  Widget build(BuildContext context) {
    List<dynamic> initials =
        widget.workspacename.split(" ").map((e) => e.substring(0, 1)).toList();
    String w_name = initials.join("");

    String? currentUserProfileImage =
        SessionStore.sessionData?.currentUser?.imageUrl;
    if (currentUserProfileImage != null && !kIsWeb) {
      currentUserProfileImage = MinioToIP.replaceMinioWithIP(
          currentUserProfileImage, ipAddressForMinio);
    }
    return Drawer(
      backgroundColor: kPriamrybackground,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 30),
                  child: ListTile(
                    leading: Text(
                      "Workspace",
                      style: TextStyle(
                          fontSize: 34,
                          color: navColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: navColor,
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: currentUserProfileImage == null
                          ? Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[300],
                              ),
                              child: Center(child: Icon(Icons.person)))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                currentUserProfileImage,
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                                errorBuilder: (BuildContext context,
                                    Object error, StackTrace? stackTrace) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    setState(() {
                                      currentUserProfileImage = null;
                                    });
                                  });
                                  return Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            width: 3, color: Colors.white),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: FittedBox(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.all(1.0),
                                        child: Text(
                                          w_name,
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: kPriamrybackground),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                      title: Text(
                        "${widget.workspacename.toString()} (${widget.username})",
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: kPriamrybackground),
                      ),
                      subtitle: Text(
                        widget.useremail,
                        style: TextStyle(color: kPriamrybackground),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            child: Column(
              children: [
                // ///////  User Management ////////
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UserManagement()));
                  },
                  hoverColor: Colors.grey.withOpacity(0.3),
                  child: ListTile(
                    leading: Icon(Icons.people_outline),
                    title: Text("User Management"),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                /////////add Channel //////////////////////
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MChannelCreate()));
                  },
                  hoverColor: Colors.grey.withOpacity(0.3),
                  child: ListTile(
                    leading: Icon(Icons.add_card_outlined),
                    title: Text("Add Channel"),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                /////////member invation //////////////////////
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MemberInvitation()));
                  },
                  hoverColor: Colors.grey.withOpacity(0.3),
                  child: ListTile(
                    leading: Icon(Icons.people_outline_outlined),
                    title: Text("Member Invitation"),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                //////////Profile ///////////////
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Profile(
                                  currentUserWorkspace: widget.workspacename,
                                )));
                  },
                  hoverColor: Colors.grey.withOpacity(0.3),
                  child: ListTile(
                    leading: Icon(Icons.account_box_outlined),
                    title: Text('Profile'),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                const Divider(),
                /////// log out //////////////
                SizedBox(
                    width: 180,
                    height: 50,
                    child: SlideAction(
                      borderRadius: 10,
                      elevation: 0,
                      innerColor: Colors.white,
                      outerColor: navColor,
                      sliderButtonIcon: const Icon(
                        Icons.logout,
                        color: Colors.black,
                        size: 13,
                      ),
                      text: 'Logout',
                      textStyle: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                      onSubmit: () async {
                        var token = await getToken();
                        await _apiService.logoutUser(token!);
                        await AuthController().removeToken();

                        // ignore: use_build_context_synchronously
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginForm()));
                      },
                    )),
                const SizedBox(
                  height: 20,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
