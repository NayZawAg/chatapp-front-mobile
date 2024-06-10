import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/model/confirm.dart';
import 'package:flutter_frontend/screens/Login/login_form.dart';
import 'package:flutter_frontend/services/confirmInvitation/confirm_member_invitation.dart';
import 'package:flutter_frontend/services/confirmInvitation/confirm_invitation_service.dart';

class ConfirmPage extends StatefulWidget {
  final int? channelId;
  final String? email;
  final int? workspaceId;

  const ConfirmPage({Key? key, this.channelId, this.email, this.workspaceId})
      : super(key: key);

  @override
  State<ConfirmPage> createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  Future<Confirm>? _confirmFuture;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _apiService = MemberInvitation();

  

  String? channelName;
  String? workspaceName;

  void _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {

        await _apiService.memberInvitationConfirm(
          passwordController.text,
          confirmPasswordController.text,
          nameController.text,
          widget.email!,
          channelName!,
          workspaceName!,
          widget.workspaceId!,
        );

        

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Sign Up Successful!',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ));
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginForm(),
            ));
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'SignUp Failed. Please check your network connection or try again later.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _confirmFuture = ConfirmInvitationService(Dio(BaseOptions(headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    }))).getConfirmData(widget.channelId!, widget.email!, widget.workspaceId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: navColor,
        title: const Center(
          child: Text(
            'Confirm Invitation',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: FutureBuilder<Confirm>(
        future: _confirmFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ProgressionBar(
              imageName: 'waiting.json',
              height: 200,
              size: 200,
            );
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Text('Error occurred or data is null');
          } else {
            var muser = snapshot.data!;
            channelName = muser.mUser!.profileImage;
            workspaceName = muser.mUser!.rememberDigest;
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Center(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextFormField(
                          initialValue: channelName,
                          enabled: false,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: widget.email,
                          enabled: false,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: workspaceName,
                          enabled: false,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Your Name',
                            hintText: 'Enter Your Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Your Name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          controller: passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter Password',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                              icon: Icon(_passwordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a Password';
                            } else if (value.length < 8) {
                              return 'Password should have at least 8 characters';
                            } else if (value.length > 10) {
                              return 'Password should have less than 10 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          controller: confirmPasswordController,
                          obscureText: !_confirmPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Enter Your Password again',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _confirmPasswordVisible =
                                      !_confirmPasswordVisible;
                                });
                              },
                              icon: Icon(_confirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please re-enter your confirmpassword';
                            } else if (value.length < 8) {
                              return 'Confirm Password Should have at least 8 characters';
                            } else if (value.length > 10) {
                              return 'Confirm Password  Should have less than 10 Characters';
                            } else if (value != passwordController.text) {
                              return 'Password and Confirm are not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            _submitForm(context);
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.lightBlue),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
