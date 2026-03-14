import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationProgramsService {
  static Stream<QuerySnapshot<Map<String, dynamic>>> programsStream({
    required String organizationId,
  }) {
    return FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('programs')
        .snapshots();
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getOrganizationDoc({
    required String organizationId,
  }) {
    return FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .get();
  }

  static Future<String> createProgram({
    required String organizationId,
    required String name,
    required String category,
    required String deadline,
    required int colorValue,
    String programStatus = 'Closed',
  }) async {
    final programDocRef = FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('programs')
        .doc();

    final programId = programDocRef.id;

    final programData = {
      'id': programId,
      'name': name,
      'category': category,
      'deadline': deadline,
      'color': colorValue,
      'organizationId': organizationId,
      'programStatus': programStatus,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await programDocRef.set(programData);
    return programId;
  }

  static Future<void> deleteProgramAndCascade({
    required String organizationId,
    required String programId,
  }) async {
    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('programs')
        .doc(programId)
        .delete();

    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    for (final userDoc in usersSnapshot.docs) {
      final userApplicationsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('users-application');

      final userApplicationsSnapshot = await userApplicationsRef
          .where('id', isEqualTo: programId)
          .get();

      for (final applicationDoc in userApplicationsSnapshot.docs) {
        await applicationDoc.reference.delete();
      }
    }
  }
}
