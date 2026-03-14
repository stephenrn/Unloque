import 'package:firebase_auth/firebase_auth.dart';

class AuthUserService {
  static Future<void> updateDisplayNameAndPhotoUrl({
    required User user,
    required String displayName,
    String? photoUrl,
  }) async {
    await user.updateDisplayName(displayName);
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }
  }
}
