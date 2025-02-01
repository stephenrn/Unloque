import 'package:flutter/material.dart';
import 'package:unloque/pages/login_page.dart';
import 'package:unloque/pages/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Unloque',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        'home': (context) => HomePage(),
      },
    );
  }
}
