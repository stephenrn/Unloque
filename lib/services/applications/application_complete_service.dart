import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:unloque/models/organization_response_section.dart';

class ApplicationCompleteService {
  static Future<Map<String, dynamic>> fetchHeaderAndResponse({
    required Map<String, dynamic> application,
    required String? uid,
  }) async {
    debugPrint("Fetching data for application: ${application['id']}");

    final programId = application['programId'] ?? application['id'];
    final organizationId = application['organizationId'] ?? application['orgId'];

    debugPrint("Using programId: $programId, organizationId: $organizationId");

    String programName = application['programName'] ?? '';
    String orgName = application['organizationName'] ?? '';
    String logoUrl = application['logoUrl'] ?? '';
    String deadline = application['deadline'] ?? '';
    String category = application['category'] ?? '';

    List<ResponseSection> responseSections = [];

    if (organizationId != null && programId != null) {
      try {
        final programDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(organizationId)
            .collection('programs')
            .doc(programId)
            .get();

        if (programDoc.exists) {
          final data = programDoc.data() ?? {};
          if (programName.isEmpty) programName = (data['name'] ?? '').toString();
          if (deadline.isEmpty) deadline = (data['deadline'] ?? '').toString();
          if (category.isEmpty) category = (data['category'] ?? '').toString();
        } else {
          debugPrint("Program document does not exist for ID: $programId");
        }

        final orgDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(organizationId)
            .get();

        if (orgDoc.exists) {
          final data = orgDoc.data() ?? {};
          if (orgName.isEmpty) orgName = (data['name'] ?? '').toString();
          if (logoUrl.isEmpty) logoUrl = (data['logoUrl'] ?? '').toString();
        } else {
          debugPrint(
              "Organization document does not exist for ID: $organizationId");
        }
      } catch (e) {
        debugPrint("Error fetching program/organization info: $e");
      }
    } else {
      debugPrint("Missing programId or organizationId");
    }

    if (programName.isEmpty) programName = application['programName'] ?? '';
    if (orgName.isEmpty) orgName = application['organizationName'] ?? '';
    if (logoUrl.isEmpty) logoUrl = application['logoUrl'] ?? '';
    if (deadline.isEmpty) deadline = application['deadline'] ?? '';
    if (category.isEmpty) category = application['category'] ?? '';

    DocumentSnapshot<Map<String, dynamic>>? formDoc;
    final appId = application['id'] ?? programId;

    if (uid != null && uid.isNotEmpty && appId != null) {
      formDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('users-application')
          .doc(appId)
          .get();

      final data = formDoc.data();
      if (data != null) {
        debugPrint("Application data found: ${data.keys}");
        final orgResponse = data['organizationResponse'];
        if (orgResponse is Map && orgResponse['responseSections'] is List) {
          final rawSections = orgResponse['responseSections'];
          responseSections = (rawSections as List)
              .whereType<Map>()
              .map((m) => ResponseSection.fromMap(
                    Map<String, dynamic>.from(m),
                  ))
              .toList(growable: false);
          debugPrint("Response sections count: ${responseSections.length}");
        } else {
          debugPrint("No organization response found in application data");
        }
      }
    } else {
      debugPrint("Unable to fetch application document - uid: $uid, appId: $appId");
    }

    return {
      'programName': programName,
      'organizationName': orgName,
      'logoUrl': logoUrl,
      'deadline': deadline,
      'category': category,
      'responseSections': responseSections,
      'formDoc': formDoc,
    };
  }
}
