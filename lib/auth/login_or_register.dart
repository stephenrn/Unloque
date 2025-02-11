import 'package:flutter/material.dart';
import '../pages/sign_in_card.dart';
import '../pages/sign_up_card.dart';

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
    return Scaffold(
      body: Center(
        child: showSignIn
            ? SignInCard(onBack: toggleView)
            : SignUpCard(onBack: toggleView),
      ),
    );
  }
}