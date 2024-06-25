import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:http/http.dart' as http;

class UserEdit extends StatefulWidget {
  final String? username;
  final String? email;
  final String? workspaceName;
  const UserEdit(
      {Key? key, required this.username, this.email, this.workspaceName})
      : super(key: key);

  @override
  State<UserEdit> createState() => _UserEditState();
}

class _UserEditState extends State<UserEdit> {
  String error = "";
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController _editUserController =
      TextEditingController(text: widget.username);
  bool _isUsernameChanging = false;
  final AuthController _authController = AuthController();
  bool _isTextBoxVisible = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              )),
          backgroundColor: navColor,
          title: const Text(
            'User Name Edit',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                    key: formKey,
                    child: Column(children: [
                      Container(
                        decoration: BoxDecoration(
                            // borderRadius: BorderRadius.all(),
                            border: Border.all(width: 2)),
                        child: ListTile(
                          leading: const Icon(Icons.email),
                          title: Text("${widget.email}"),
                        ),
                      ),
                      const SizedBox(
                        height: defaultPadding / 2,
                      ),
                      Container(
                        decoration: BoxDecoration(border: Border.all(width: 2)),
                        child: ListTile(
                          leading: const Icon(Icons.work),
                          title: Text("${widget.workspaceName}"),
                        ),
                      ),
                      const SizedBox(
                        height: defaultPadding / 2,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: TextFormField(
                          controller: _editUserController,
                          textInputAction: TextInputAction.done,
                          cursorColor: kPrimaryColor,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter Your Name';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: "Enter Your Name",
                          ),
                        ),
                      ),
                      Visibility(
                        visible: _isTextBoxVisible,
                        child: Container(
                          width: 450.0,
                          color: const Color.fromARGB(
                              255, 233, 201, 211), // Background color
                          padding: const EdgeInsets.all(
                              8.0), // Padding around the text
                          child: Center(
                            child: Text(
                              "Name $error",
                              style: const TextStyle(
                                color: Color.fromARGB(
                                    255, 223, 59, 47), // Text color
                                // Add more text styling as needed
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: defaultPadding / 2,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: ElevatedButton(
                          onPressed: () {
                            editUsername(_editUserController.text.trimRight());
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(
                                kPrimarybtnColor),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (!_isUsernameChanging)
                                const Text('Change Username')
                              else
                                ProgressionBar(
                                    imageName: 'mailSending2.json',
                                    height: MediaQuery.sizeOf(context).height,
                                    size: MediaQuery.sizeOf(context).width)
                            ],
                          ),
                        ),
                      )
                    ]))),
          ),
        ));
  }

  Future<void> editUsername(String username) async {
    var token = await AuthController().getToken();
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      try {
        setState(() {
          _isUsernameChanging = true;
        });
        final response = await http.patch(
            Uri.parse("http://10.0.2.2:3000/m_users/edit_username"),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{"username": username}));
        final body = json.decode(response.body);

        if (response.statusCode == 200) {
          setState(() {
            _isTextBoxVisible = false;

            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('User name has been successfully changed'),
              backgroundColor: Colors.green,
            ));
          });
        } else if (response.statusCode == 422) {
          setState(() {
            _isTextBoxVisible = true;
            error = body["error_message"]["name"].join("\nName ");
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Failed to change user name'),
              backgroundColor: Colors.red,
            ));
          });
        }
      } catch (e) {
        print("error $e");

        rethrow;
      } finally {
        setState(() {
          _isUsernameChanging = false;
        });
      }
    }
  }
}
