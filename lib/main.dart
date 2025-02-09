import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unloque/pages/login_page.dart';
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
        '/': (context) => LoginPage(),
        'home': (context) => HomePage(),
        '/sampleartceducation': (context) => SampleArtcEducationPage(),
        '/sampleartchealthcare': (context) => SampleArtcHealthcarePage(),
      },
    );
  }
}
