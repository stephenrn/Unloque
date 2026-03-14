import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class UserProfileImageService {
  static Future<String> uploadProfileImage({
    required String uid,
    required File imageFile,
  }) async {
    final ext = p.extension(imageFile.path);
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}$safeExt';

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child(fileName);

    final snapshot = await storageRef.putFile(imageFile);
    return snapshot.ref.getDownloadURL();
  }
}
