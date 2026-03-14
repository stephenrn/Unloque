import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationNewsService {
  static Stream<QuerySnapshot<Map<String, dynamic>>> newsStream({
    required String organizationId,
  }) {
    return FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('news')
        .orderBy('date', descending: true)
        .snapshots();
  }

  static Future<void> upsertNews({
    required String organizationId,
    required String? docId,
    required Map<String, dynamic> data,
  }) async {
    final dataWithTimestamp = {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final collectionRef = FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('news');

    if (docId == null) {
      await collectionRef.add(dataWithTimestamp);
      return;
    }

    await collectionRef.doc(docId).update(dataWithTimestamp);
  }

  static Future<void> deleteNews({
    required String organizationId,
    required String docId,
  }) {
    return FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('news')
        .doc(docId)
        .delete();
  }
}
