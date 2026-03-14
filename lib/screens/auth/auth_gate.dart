import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unloque/services/auth/auth_session_service.dart';
import 'package:unloque/screens/home_page.dart';
import 'package:unloque/screens/welcome_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthSessionService.authStateChanges(),
      builder: (context, snapshot) {
        // If the user is already logged in
        if (snapshot.hasData) {
          return const HomePage();
        }

        // Otherwise, show the welcome page with Google sign-in
        return WelcomePage();
      },
    );
  }
}
