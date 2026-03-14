import 'package:firebase_auth/firebase_auth.dart';

class AuthSessionService {
  static User? currentUser() => FirebaseAuth.instance.currentUser;

  static String? currentUid() => FirebaseAuth.instance.currentUser?.uid;

  static Stream<User?> authStateChanges() => FirebaseAuth.instance.authStateChanges();

  static Future<void> signOut() => FirebaseAuth.instance.signOut();
}
