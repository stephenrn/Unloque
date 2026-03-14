import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:unloque/providers/available_applications_provider.dart';
import 'package:unloque/providers/user_applications_provider.dart';
import 'package:unloque/screens/auth/auth_gate.dart';
import 'package:unloque/screens/home_page.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AvailableApplicationsProvider()),
        ChangeNotifierProvider(create: (_) => UserApplicationsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Unloque',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const AuthGate(),
        routes: {
          'home': (context) => const HomePage(),
        },
      ),
    );
  }
}
