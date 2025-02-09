import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:unloque/auth/login_or_register.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginOrRegister()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.black, // Outline color
            height: 1.0, // Outline height
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text("Profile Page"),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => signOut(context),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
