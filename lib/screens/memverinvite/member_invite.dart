import 'package:mailer/mailer.dart';
import 'package:flutter/material.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/services/memberinvite/MemberInvite.dart';
// ignore_for_file: use_build_context_synchronously, prefer_const_constructors



class MemberInvitation extends StatefulWidget {
  const MemberInvitation({Key? key}) : super(key: key);
  @override
  State<MemberInvitation> createState() => _MemberInvitationState();
}

class _MemberInvitationState extends State<MemberInvitation> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  String workSpaceName =
      SessionStore.sessionData!.mWorkspace!.workspaceName.toString();
  int workspaceId = SessionStore.sessionData!.mWorkspace!.id!.toInt();
  int channelLength = SessionStore.sessionData!.mChannels!.length.toInt();
  String currentUser = SessionStore.sessionData!.currentUser!.name!.toString();
  String currentUserEmail =
      SessionStore.sessionData!.currentUser!.email.toString();
  int? channelId;
  String? channelName;
  bool _isSendingEmail = false;
  bool btnDisable = true;

  late List<bool> selected;

  Future<void> _submitEmail(
      String email, int channelId, BuildContext context) async {
    if (_formKey.currentState!.validate() || channelId != null) {
      try {
        setState(() {
          btnDisable = false;
          _isSendingEmail = true;
        });
        await MemberInviteServices().memberInvite(email, channelId);

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Email has Already used..'),
          backgroundColor: Colors.red,
        ));
      } finally {
        setState(() {
          _isSendingEmail = false;
          btnDisable = true;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please Selected Channel'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void sendMail({required String recipientEmail}) async {
    String username = 'shonlantkhaing@gmail.com';
    String password = 'eghe dazw irat rusn';
    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Slack')
      ..recipients.add(recipientEmail)
      ..subject = 'Hello! I want you to Join our Workspace.'
      ..html = "<h1 style='color: black;'>Accept ${currentUser}'s invitation to Slack</h1>"
          "<p style='color: black;'><b>${currentUser}</b> (<a href='#' target='_blank'>${currentUserEmail}</a>) has invited you to use Slack with them, in a channel called <b>${channelName}</b>.</p>"
          "<div style='background: #f2f2f2;padding: 20px 40px;color: black;text-align: center;'>"
          "<div style='padding-top: 1px;padding-bottom: 1px;margin: auto;width: 75px;color: white;background: #0576b9;border-radius: 50%;'><p style='font-size: 20px;font-weight: bold;'>${channelName}</p></div>"
          "<p style='font-weight: bold;font-size: 20px;'>${channelName}</p>"
          "<a href='https://confirmmail-81b95.web.app/?path=confirminvitation&workspaceId=${workspaceId}&channelId=${channelId}&email=${emailController.text.toString()}' style='margin: 30px auto;background: purple;text-decoration: none;padding: 14px 26px;border-radius: 8px;color: white;font-weight: bold;'>JOIN NOW</a>"
          "<p>Join the conversation with <b>${currentUser}</b> and <br> <b>other member</b></p>"
          "</div>"
          "<p style='color: black;'>Once you join, you can always access the <b>${channelName}</b> channel</p>";
    try {
      await send(message, smtpServer);
      print('Email sent fu to $recipientEmail');
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  @override
  void initState() {
    super.initState();
    selected = List.generate(channelLength, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPriamrybackground,
      appBar: AppBar(
        backgroundColor: navColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
           
          },
          icon: const Icon(Icons.arrow_back,color: Colors.white,),
        ),
        title: const Text(
          'Member Invitation',
          style: TextStyle(color: Colors.white),
        ),
        
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Invite to $workSpaceName',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16.0),
              SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(border: Border.all(width: 3)),
                  height: 200,
                  child: ListView.builder(
                    itemCount: channelLength,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: SessionStore
                                .sessionData!.mChannels![index].channelStatus!
                            ? const Icon(Icons.tag)
                            : const Icon(Icons.lock),
                        enableFeedback: true,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        title: TextButton(
                         style: ButtonStyle(
                             backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                              if (states.contains(MaterialState.pressed)) {
                                // Change the color when button is pressed
                                return Colors.amber.shade100;
                              }
                              // Return the default color when button is not pressed
                              return kPriamrybackground;
                            }),
                            ),
                          onPressed: () {
                            setState(() {
                              for (var i = 0; i < selected.length; i++) {
                                if (i != index) {
                                  selected[i] = false;
                                }
                              }
                              channelId = SessionStore
                                  .sessionData!.mChannels![index].id!;
                              channelName = SessionStore
                                  .sessionData!.mChannels![index].channelName;
                            });
                          },
                          child: ListTile(
                            title: Text(
                              SessionStore
                                  .sessionData!.mChannels![index].channelName
                                  .toString(),
                              style: TextStyle(
                                  color: selected[index]
                                      ? Colors.green
                                      : Colors.deepPurple),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Form(
                key: _formKey,
                child: TextFormField(
                    controller: emailController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: kPrimaryColor,
                    autocorrect: true,
                    decoration: const InputDecoration(
                      hintText: "Invite with Email",
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(defaultPadding),
                        child: Icon(Icons.email),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an Email';
                      }
                      if (!RegExp(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
                              caseSensitive: false)
                          .hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    }),
              ),
              const SizedBox(height: 10),
              Visibility(
                visible:
                    _isSendingEmail, // Show loading indicator if email is being sent
                child: const Column(
                  children: [
                    ProgressionBar(
                      color: Colors.white,
                        imageName: 'dataSending.json',
                         height: 100,
                          size: 100),
                    SizedBox(height: 8.0),
                    Text('Sending email...'),
                  ],
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.blue)),
                onPressed: !btnDisable
                    ? null
                    : () {
                        // Check if email is already being sent
                        if (!_isSendingEmail) {
                          if (channelId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Channel is not selected'),
                              backgroundColor: Colors.red,
                            ));
                          } else {
                            if (emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('Email is empty'),
                                backgroundColor: Colors.red,
                              ));
                            } else if (!RegExp(
                                    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
                                    caseSensitive: false)
                                .hasMatch(emailController.text)) {
                                  ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('Please enter a valid email address'),
                                backgroundColor: Colors.red,
                              ));
                             
                            } else {
                              _submitEmail(
                                  emailController.text, channelId!, context);
                              // sendMail(
                              //     recipientEmail:
                              //         emailController.text.toString());
                            }
                          }
                        }
                      },
                child: Text('Invite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
