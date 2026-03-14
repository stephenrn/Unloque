import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ApplicationPendingService {
  static Future<Map<String, dynamic>> fetchHeaderDataAndForm({
    required Map<String, dynamic> application,
    required String? uid,
  }) async {
    final programId = application['programId'] ?? application['id'];
    final organizationId = application['organizationId'] ?? application['orgId'];

    String programName = '';
    String orgName = '';
    String logoUrl = '';
    String deadline = '';
    String category = '';

    debugPrint('Fetching programId: $programId, organizationId: $organizationId');

    if (organizationId != null && programId != null) {
      try {
        final programDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(organizationId.toString())
            .collection('programs')
            .doc(programId.toString())
            .get();

        if (programDoc.exists) {
          final data = programDoc.data() ?? {};
          programName = (data['name'] ?? '').toString();
          deadline = (data['deadline'] ?? '').toString();
          category = (data['category'] ?? '').toString();
          debugPrint('Fetched program: $programName, $deadline, $category');
        }

        final orgDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(organizationId.toString())
            .get();

        if (orgDoc.exists) {
          final data = orgDoc.data() ?? {};
          orgName = (data['name'] ?? '').toString();
          logoUrl = (data['logoUrl'] ?? '').toString();
          debugPrint('Fetched org: $orgName, $logoUrl');
        }
      } catch (e) {
        debugPrint('Error fetching header data: $e');
      }
    }

    if (programName.isEmpty) programName = (application['programName'] ?? '').toString();
    if (orgName.isEmpty) orgName = (application['organizationName'] ?? '').toString();
    if (logoUrl.isEmpty) logoUrl = (application['logoUrl'] ?? '').toString();
    if (deadline.isEmpty) deadline = (application['deadline'] ?? '').toString();
    if (category.isEmpty) category = (application['category'] ?? '').toString();

    debugPrint(
      'Display programName: $programName, orgName: $orgName, logoUrl: $logoUrl, deadline: $deadline, category: $category',
    );

    DocumentSnapshot? formDoc;
    final appId = application['id'] ?? programId;

    if (uid != null && appId != null) {
      try {
        formDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('users-application')
            .doc(appId.toString())
            .get();
      } catch (e) {
        debugPrint('Error fetching form document: $e');
      }
    }

    return {
      'programName': programName,
      'organizationName': orgName,
      'logoUrl': logoUrl,
      'deadline': deadline,
      'category': category,
      'formDoc': formDoc,
    };
  }
}
