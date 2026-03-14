import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationFormService {
  static Future<void> saveFormFields({
    required String uid,
    required String applicationId,
    required List<Map<String, dynamic>> formFields,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('users-application')
        .doc(applicationId)
        .update({'formFields': formFields});
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserApplicationDoc({
    required String uid,
    required String applicationId,
  }) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('users-application')
        .doc(applicationId)
        .get();
  }

  static Future<Map<String, dynamic>?> getUserApplicationData({
    required String uid,
    required String applicationId,
  }) async {
    final doc = await getUserApplicationDoc(uid: uid, applicationId: applicationId);
    return doc.data();
  }

  static Future<void> deleteUserApplication({
    required String uid,
    required String applicationId,
  }) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('users-application')
        .doc(applicationId)
        .delete();
  }

  static Future<void> updateStatus({
    required String uid,
    required String applicationId,
    required String status,
  }) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('users-application')
        .doc(applicationId)
        .update({'status': status});
  }
}
