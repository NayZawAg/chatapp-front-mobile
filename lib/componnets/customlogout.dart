import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/Login/login_form.dart';


class CustomLogOut extends StatefulWidget {
  const CustomLogOut({ super.key});

  @override
  _CustomLogOutState createState() => _CustomLogOutState();
}

class _CustomLogOutState extends State<CustomLogOut> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    const time = Duration(milliseconds: 10000);
    _timer = Timer(time, () {
      // After 10 seconds, navigate to the login form
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginForm(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer!.cancel(); // Dispose the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const  Text(
              "You have been deactivated!",
              style: TextStyle(color: Colors.red),
            ),
           const  SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Navigate to the login form immediately when pressed
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginForm(),
                  ),
                );
              },
              child: const  Text('Logout'),
            )
          ],
        ),
      ),
    );
  }
}
