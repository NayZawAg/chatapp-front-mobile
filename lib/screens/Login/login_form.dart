import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/theme/app_color.dart';
import 'package:flutter_frontend/screens/signup/signup_screen.dart';
import 'package:flutter_frontend/componnets/already_have_an_account_acheck.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _workspaceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthController _authController = AuthController();
  bool _isLoading = false;

  Future<void> _signIn(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      _formKey.currentState!.save();
      int? status = await _authController.loginUser(_nameController.text.trimRight(),
          _passwordController.text.trimRight(), _workspaceController.text.trimRight(), context);


      setState(() {
        _isLoading = false;
      });

      if (status == 200) {
        _nameController.clear();
        _passwordController.clear();
        _workspaceController.clear();
        // ignore: use_build_context_synchronously

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Sign In Successful!',
           
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ));
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Nav()));
      } else if (status == 401) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Account Deactivate. Please contact admin.',
            
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      } else if (status == 404) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid workspace name combination'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      } else if (status == 422) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid name/password combination'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _workspaceController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6E2EA),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              height: 64,
              width: 64,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: const Image(image: AssetImage("assets/images/slack.jpg")),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              width: 250,
              child: SvgPicture.asset("assets/icons/login.svg"),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      cursorColor: kPrimaryColor,
                      decoration:  const InputDecoration(
                        hintText: "Your Name",
                        prefixIcon:  Padding(
                          padding: EdgeInsets.all(defaultPadding),
                          child: Icon(Icons.person),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      textInputAction: TextInputAction.done,
                      obscureText: true,
                      cursorColor: kPrimaryColor,
                      decoration: const  InputDecoration(
                        hintText: "Your password",
                        prefixIcon:  Padding(
                          padding: EdgeInsets.all(defaultPadding),
                          child: Icon(Icons.lock),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _workspaceController,
                      textInputAction: TextInputAction.next,
                      cursorColor: kPrimaryColor,
                      decoration: const InputDecoration(
                        hintText: "Your Workspace Name",
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(defaultPadding),
                          child: Icon(Icons.work),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your workspace name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async => await _signIn(context),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              kPrimarybtnColor),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : Text("Login".toUpperCase()),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AlreadyHaveAnAccountCheck(
                      press: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
