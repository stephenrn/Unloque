import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationApplicationService {
  static Future<Map<String, dynamic>?> buildApplicationForNotification({
    required String uid,
    required Map<String, dynamic> notification,
  }) async {
    final applicationId = notification['applicationId'];
    if (applicationId == null) return null;

    final applicationDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('users-application')
        .doc(applicationId)
        .get();

    if (!applicationDoc.exists) {
      return null;
    }

    final appData = applicationDoc.data() as Map<String, dynamic>;

    final programId =
        appData['programId'] ?? notification['programId'] ?? applicationId;
    final orgId = appData['organizationId'] ??
        notification['organizationId'] ??
        appData['orgId'];

    final Map<String, dynamic> completeAppData = {
      ...appData,
      'id': applicationId,
      'programId': programId,
      'organizationId': orgId,
    };

    if (orgId != null && programId != null) {
      try {
        final programDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('programs')
            .doc(programId)
            .get();

        if (programDoc.exists) {
          final programData = programDoc.data() as Map<String, dynamic>;

          if (!completeAppData.containsKey('programName') &&
              programData.containsKey('name')) {
            completeAppData['programName'] = programData['name'];
          }

          if (!completeAppData.containsKey('categoryColor') &&
              programData.containsKey('color')) {
            final colorValue = programData['color'];
            if (colorValue is int) {
              completeAppData['categoryColor'] = Color(colorValue);
            } else {
              completeAppData['categoryColor'] = Colors.grey;
            }
          }

          if (!completeAppData.containsKey('deadline') &&
              programData.containsKey('deadline')) {
            completeAppData['deadline'] = programData['deadline'];
          }

          if (!completeAppData.containsKey('category') &&
              programData.containsKey('category')) {
            completeAppData['category'] = programData['category'];
          }
        }

        final orgDoc =
            await FirebaseFirestore.instance.collection('organizations').doc(orgId).get();

        if (orgDoc.exists) {
          final orgData = orgDoc.data() as Map<String, dynamic>;

          if (!completeAppData.containsKey('organizationName') &&
              orgData.containsKey('name')) {
            completeAppData['organizationName'] = orgData['name'];
          }

          if (!completeAppData.containsKey('logoUrl') &&
              orgData.containsKey('logoUrl')) {
            completeAppData['logoUrl'] = orgData['logoUrl'];
          }
        }
      } catch (e) {
        // Intentionally continue with partial data
        // (keeps the UI behavior lenient and non-blocking)
        debugPrint('Error fetching additional program info: $e');
      }
    }

    return completeAppData;
  }
}
