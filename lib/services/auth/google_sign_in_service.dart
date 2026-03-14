import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
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
