import 'package:cloud_firestore/cloud_firestore.dart';

class ProgramPreviewService {
  static Future<Map<String, dynamic>?> fetchProgram({
    required String organizationId,
    required String programId,
  }) async {
    final programDoc = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('programs')
        .doc(programId)
        .get();

    if (!programDoc.exists) return null;

    final data = programDoc.data();
    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>?> fetchOrganization({
    required String organizationId,
  }) async {
    final orgDoc = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .get();

    if (!orgDoc.exists) return null;

    final data = orgDoc.data();
    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }
}
