import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unloque/models/organization_response_section.dart';

class OrganizationResponseService {
  static Future<Map<String, String>> fetchHeaderData({
    required String? organizationId,
    required String? programId,
  }) async {
    String programName = '';
    String orgName = '';
    String logoUrl = '';
    String deadline = '';
    String category = '';

    if (organizationId != null && programId != null) {
      final programDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('programs')
          .doc(programId)
          .get();

      if (programDoc.exists) {
        final data = programDoc.data() ?? {};
        programName = (data['name'] ?? '').toString();
        deadline = (data['deadline'] ?? '').toString();
        category = (data['category'] ?? '').toString();
      }

      final orgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .get();

      if (orgDoc.exists) {
        final data = orgDoc.data() ?? {};
        orgName = (data['name'] ?? '').toString();
        logoUrl = (data['logoUrl'] ?? '').toString();
      }
    }

    return {
      'programName': programName,
      'orgName': orgName,
      'logoUrl': logoUrl,
      'deadline': deadline,
      'category': category,
    };
  }

  static Future<void> sendResponse({
    required String? organizationId,
    required String? userId,
    required String? applicationId,
    required String? programId,
    required String orgName,
    required String programName,
    required List<ResponseSection> responseSections,
  }) async {
    if (organizationId == null || organizationId.isEmpty) {
      throw Exception('Missing organizationId');
    }
    if (userId == null || userId.isEmpty) {
      throw Exception('Missing userId');
    }
    if (applicationId == null || applicationId.isEmpty) {
      throw Exception('Missing applicationId');
    }

    final userAppRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('users-application')
        .doc(applicationId);

    await userAppRef.update({
      'organizationResponse': {
        'organizationId': organizationId,
        'userId': userId,
        'applicationId': applicationId,
        'responseSections':
            responseSections.map((s) => s.toPersistedMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      'status': 'Completed',
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'Response Received',
      'message':
          'Organization $orgName has responded to your application for $programName',
      'type': 'response',
      'programId': programId ?? applicationId,
      'programName': programName,
      'organizationId': organizationId,
      'organizationName': orgName,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      'applicationId': applicationId,
    });
  }
}
