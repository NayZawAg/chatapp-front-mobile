import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';

class ChangePassword extends StatefulWidget {
  final String? email;

  const ChangePassword({Key? key, this.email}) : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late AuthController _authController;
  bool _isPasswordChanging = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _authController = AuthController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                          controller: _passwordController,
                          textInputAction: TextInputAction.done,
                          obscureText: !_passwordVisible,
                          cursorColor: kPrimaryColor,
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
                            } else if (value.length < 8) {
                              return 'Confirm Password Should have at least 8 characters';
                            } else if (value.length > 10) {
                              return 'Confirm Password  Should have less than 10 Characters';
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: ElevatedButton(
                          onPressed:
                              _isPasswordChanging ? null : handleChangePassword,
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
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
                      )
                    ]))),
          ),
        ));
  }

  Future<void> handleChangePassword() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      try {
        setState(() {
          _isPasswordChanging = true;
        });
        await _authController.changePassword(
          _passwordController.text.trimRight(),
          _confirmPasswordController.text.trimRight(),
        );
        _passwordController.clear();
        _confirmPasswordController.clear();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password has been changed'),
          backgroundColor: Colors.green,
        ));
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to change password'),
          backgroundColor: Colors.red,
        ));
      } finally {
        setState(() {
          _isPasswordChanging = false;
        });
      }
    }
  }
}
