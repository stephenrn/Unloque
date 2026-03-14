import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationMapDataService {
  static Stream<QuerySnapshot<Map<String, dynamic>>> organizationMapDataStream({
    required String organizationId,
  }) {
    return FirebaseFirestore.instance
        .collection('mapdata')
        .where('organizationId', isEqualTo: organizationId)
        .snapshots();
  }

  static Future<void> deleteMapDataDoc({
    required String docId,
  }) {
    return FirebaseFirestore.instance.collection('mapdata').doc(docId).delete();
  }
}
