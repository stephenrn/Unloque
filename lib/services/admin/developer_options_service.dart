import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DeveloperOptionsService {
  static String generateOrganizationId() {
    return FirebaseFirestore.instance.collection('organizations').doc().id;
  }

  static Future<void> createOrganization({
    required String organizationId,
    required String name,
    required String logoUrl,
    required String website,
  }) async {
    final organizationData = {
      'id': organizationId,
      'name': name,
      'logoUrl': logoUrl,
      'website': website,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .set(organizationData);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> organizationsStream() {
    return FirebaseFirestore.instance
        .collection('organizations')
        .snapshots();
  }

  static Future<void> deleteOrganizationData({
    required String organizationId,
  }) async {
    // 1) Collect program storage refs before deleting program docs.
    final List<Reference> storageRefsToDelete = [];

    // 2) Get all programs.
    final programsSnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('programs')
        .get();

    for (final programDoc in programsSnapshot.docs) {
      final programId = programDoc.id;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('organizations/$organizationId/programs/$programId');

      storageRefsToDelete.add(storageRef);

      await programDoc.reference.delete();
    }

    // 3) Delete the organization doc.
    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .delete();

    // 4) Delete program folders.
    for (final storageRef in storageRefsToDelete) {
      await _recursivelyDeleteFolder(storageRef);
    }

    // 5) Delete the org folder.
    final orgStorageRef =
        FirebaseStorage.instance.ref().child('organizations/$organizationId');
    await _recursivelyDeleteFolder(orgStorageRef);
  }

  static Future<void> _recursivelyDeleteFolder(Reference storageRef) async {
    final ListResult result = await storageRef.listAll();

    for (final item in result.items) {
      try {
        await item.delete();
      } catch (_) {
        // Best-effort deletion; continue
      }
    }

    for (final prefix in result.prefixes) {
      await _recursivelyDeleteFolder(prefix);
    }
  }
}
