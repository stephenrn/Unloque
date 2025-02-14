import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unloque/pages/welcome_page.dart';
import 'package:unloque/auth/login_or_register.dart';
import 'package:unloque/pages/home_page.dart';
import 'package:unloque/pages/sample_artc_education_page.dart';
import 'package:unloque/pages/sample_artc_healthcare_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
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
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomePage(),
        'home': (context) => HomePage(),
        '/sampleartceducation': (context) => SampleArtcEducationPage(),
        '/sampleartchealthcare': (context) => SampleArtcHealthcarePage(),
      },
    );
  }
}
