import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unloque/auth/auth_gate.dart';
import 'package:unloque/pages/home_page.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Request storage permission
  await Permission.storage.request();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Unloque',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthGate(),
      routes: {
        'home': (context) => HomePage(),
      },
    );
  }
}
