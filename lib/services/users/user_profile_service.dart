import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  static Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(
    String uid,
  ) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(
    String uid,
  ) {
    return FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  static Future<bool> userExists(String uid) async {
    final doc = await getUserDoc(uid);
    return doc.exists;
  }

  static Future<void> createUserProfile({
    required String uid,
    required String email,
    required String username,
    String? photoUrl,
  }) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'uid': uid,
        'email': email,
        'username': username,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> ensureUidAndTrackLogin(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).update({
      'uid': uid,
      'lastLogin': Timestamp.now(),
    });
  }

  static Future<void> updateProfile({
    required String uid,
    required String username,
    required String phone,
    required String address,
    String? photoUrl,
  }) {
    final updateData = {
      'username': username,
      'phone': phone,
      'address': address,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };

    return FirebaseFirestore.instance.collection('users').doc(uid).update(
          updateData,
        );
  }
}
