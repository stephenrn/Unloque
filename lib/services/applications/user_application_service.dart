import 'package:cloud_firestore/cloud_firestore.dart';

class UserApplicationService {
  static Future<String?> getUserApplicationStatus({
    required String uid,
    required String applicationId,
  }) async {
    final applicationDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('users-application')
        .doc(applicationId)
        .get();

    if (!applicationDoc.exists) return null;
    return applicationDoc.data()?['status'] as String?;
  }

  static Future<bool> userApplicationExists({
    required String uid,
    required String applicationId,
  }) async {
    final applicationDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('users-application')
        .doc(applicationId)
        .get();

    return applicationDoc.exists;
  }

  static Future<void> createUserApplication({
    required String uid,
    required String applicationId,
    String status = 'Ongoing',
  }) async {
    final applicationData = {
      'id': applicationId,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('users-application')
        .doc(applicationId)
        .set(applicationData);
  }
}
