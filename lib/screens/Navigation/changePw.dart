import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:http/http.dart' as http;

class ChangePassword extends StatefulWidget {
  final String? email;

  const ChangePassword({Key? key, this.email}) : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool _oldPasswordVisible = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  TextEditingController _oldPasswordController = TextEditingController();
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late AuthController _authController;
  bool _isPasswordChanging = false;
  bool _isTextBoxVisible = false;
  String error = "";
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _oldPasswordController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _authController = AuthController();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  //for cheecking password format
  bool _validatePassword(String password) {
    String _errorMessage = '';

    // Regex pattern for password validation
    RegExp passwordPattern =
        RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%&*~]).{8,}$');

    if (!passwordPattern.hasMatch(password)) {
      _errorMessage =
          'Password must be at least 8 characters long and contain \nat least one uppercase letter, one lowercase letter, \none digit, and one special character.';
    }

    if (_errorMessage.isEmpty) {
      return true;
    } else {
      setState(() {
        error = _errorMessage;
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kPriamrybackground,
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
            'Change Password',
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
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: Text("${widget.email}"),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: TextFormField(
                          controller: _oldPasswordController,
                          textInputAction: TextInputAction.done,
                          obscureText: !_oldPasswordVisible,
                          cursorColor: kPrimaryColor,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your old Password';
                            } else if (value.length < 8) {
                              return 'Password should have at least 8 characters';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Enter Your current password",
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(defaultPadding),
                              child: Icon(Icons.lock),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _oldPasswordVisible = !_oldPasswordVisible;
                                });
                              },
                              icon: Icon(_oldPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: TextFormField(
                          controller: _passwordController,
                          textInputAction: TextInputAction.done,
                          obscureText: !_passwordVisible,
                          cursorColor: kPrimaryColor,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a Password';
                            } else if (!_validatePassword(value)) {
                              return error;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Enter Your password",
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(defaultPadding),
                              child: Icon(Icons.lock),
                            ),
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
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          textInputAction: TextInputAction.done,
                          obscureText: !_confirmPasswordVisible,
                          cursorColor: kPrimaryColor,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please re-enter your confirmpassword';
                            } else if (value != _passwordController.text) {
                              return 'Password and Confirm are not match';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Confirm Your password",
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(defaultPadding),
                              child: Icon(Icons.lock),
                            ),
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
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: defaultPadding / 2,
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
                              error,
                              style: const TextStyle(
                                color: Color.fromARGB(
                                    255, 223, 59, 47), // Text color
                                // Add more text styling as needed
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: ElevatedButton(
                          onPressed: () {
                            changePw(
                                _oldPasswordController.text.trimRight(),
                                _passwordController.text.trimRight(),
                                _oldPasswordController.text.trimRight());
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color>(
                                kPrimarybtnColor),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (!_isPasswordChanging)
                                const Text('Change Password')
                              else
                                ProgressionBar(
                                    imageName: 'mailSending2.json',
                                    height: MediaQuery.sizeOf(context).height,
                                    size: MediaQuery.sizeOf(context).width)
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    size: 14.0,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                      "Password must contain at least 8 characters"),
                                ],
                              ),
                              UnorderedListItem("1 lowercase letter"),
                              UnorderedListItem("1 uppercase letter"),
                              UnorderedListItem("1 digit"),
                              UnorderedListItem("1 special character"),
                            ],
                          ),
                        ),
                      )
                    ]))),
          ),
        ));
  }

  Future<void> changePw(
      String oldPassword, String password, String passwordConfirmation) async {
    int currentUser = SessionStore.sessionData!.currentUser!.id!.toInt();
    var token = await AuthController().getToken();
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      try {
        setState(() {
          _isPasswordChanging = true;
        });
        final response = await http.put(
            Uri.parse("http://10.0.2.2:3000/m_users/$currentUser"),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, Map>{
              "m_user": {
                "old_password": oldPassword,
                "password": password,
                "password_confirmation": passwordConfirmation
              }
            }));

        final body = json.decode(response.body);
        if (response.statusCode == 200 && body["error"] == null) {
          setState(() {
            _isTextBoxVisible = false;

            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Password has been successfully changed'),
              backgroundColor: Colors.green,
            ));
          });
        } else {
          setState(() {
            _isTextBoxVisible = true;
            error = body["error"];
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Failed to change Password'),
              backgroundColor: Colors.red,
            ));
          });
        }
      } catch (e) {
        rethrow;
      } finally {
        setState(() {
          _isPasswordChanging = false;
        });
      }
    }
  }
}

class UnorderedListItem extends StatelessWidget {
  final String text;

  UnorderedListItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 13.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(
              height: 1,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
