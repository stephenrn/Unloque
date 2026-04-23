import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

enum GoogleSignInStage {
  connecting,
  authenticating,
  signingIn,
}

typedef GoogleSignInStageCallback = void Function(GoogleSignInStage stage);

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Starts Google sign-in and signs into Firebase.
  /// Returns null if the user cancels the Google account picker.
  static Future<UserCredential?> signInWithGoogle({
    GoogleSignInStageCallback? onStage,
  }) async {
    onStage?.call(GoogleSignInStage.connecting);
    final GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      final String raw = e.toString();
      final String message = (e.message ?? '').toString();
      final String details = (e.details ?? '').toString();

      final bool isApi10 = raw.contains('ApiException: 10') ||
          message.contains('ApiException: 10') ||
          details.contains('ApiException: 10');

      if (e.code == 'sign_in_failed' && isApi10) {
        throw Exception(
          'Google Sign-In is misconfigured for Android (ApiException: 10). '
          'Add your app signing SHA-1 in Firebase Console → Project settings → Your Android app, '
          'download a fresh android/app/google-services.json, then rebuild the app.',
        );
      }

      rethrow;
    }
    if (googleUser == null) return null;

    onStage?.call(GoogleSignInStage.authenticating);
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    onStage?.call(GoogleSignInStage.signingIn);
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  static Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
