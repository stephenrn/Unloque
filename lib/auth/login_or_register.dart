import 'package:flutter/material.dart';
import '../pages/sign_in_page.dart';
import '../pages/sign_up_page.dart';

class LoginOrRegister extends StatefulWidget {
  @override
  _LoginOrRegisterState createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  bool showSignIn = true;

  void toggleView() {
    setState(() {
      showSignIn = !showSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return showSignIn ? LoginPage(toggleView: toggleView) : SignUpPage(toggleView: toggleView);
  }
}