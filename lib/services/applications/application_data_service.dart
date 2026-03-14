import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unloque/services/auth/auth_session_service.dart';
import 'package:unloque/models/program_form_field.dart';
import 'package:unloque/models/organization_response_section.dart';

class ApplicationDataService {
  // Get all user applications with full details
  static Future<List<Map<String, dynamic>>> getUserApplications() async {
    final uid = AuthSessionService.currentUid();
    if (uid == null) {
      throw Exception('User not signed in');
    }

    try {
      // Get all applications for this user
      final userAppSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('users-application')
          .get();

      if (userAppSnapshot.docs.isEmpty) {
        return [];
      }

      // Create a list to store the full application details
      final List<Map<String, dynamic>> userApplications = [];

      // Fetch full details for each application
      for (final appDoc in userAppSnapshot.docs) {
        final appData = appDoc.data();
        final programId =
            (appData['programId'] ?? appData['id'] ?? appDoc.id).toString();

        // Get the organization that owns this program
        final programDetails = await _fetchProgramDetails(programId);

        final merged = <String, dynamic>{
          // Start with user-side application fields
          ...appData,
          // Overlay program details (if available)
          ...programDetails,
        };

        // Canonical identifiers (avoid being overridden by appData)
        merged['id'] = programId;
        merged['programId'] = programId;
        merged['organizationId'] =
            (appData['organizationId'] ?? programDetails['organizationId'] ?? '')
                .toString();

        // Required UI fields + safe defaults
        merged['status'] = (appData['status'] ?? merged['status'] ?? 'Unknown');
        merged['programName'] =
            (merged['programName'] ?? 'Unknown Program').toString();
        merged['organizationName'] =
            (merged['organizationName'] ?? 'Unknown Organization').toString();
        merged['deadline'] = (merged['deadline'] ?? 'No Deadline').toString();
        merged['category'] = (merged['category'] ?? 'Uncategorized').toString();

        // Ensure categoryColor is a Color (History UI assumes Color)
        final rawCategoryColor = merged['categoryColor'];
        if (rawCategoryColor is int) {
          merged['categoryColor'] = Color(rawCategoryColor);
        } else if (rawCategoryColor is! Color) {
          merged['categoryColor'] = Colors.blue[200]!;
        }

        userApplications.add(merged);
      }

      return userApplications;
    } catch (e) {
      print('Error fetching user applications: $e');
      return [];
    }
  }

  // Get applications filtered by status
  static Future<List<Map<String, dynamic>>> getApplicationsByStatus(
      String status) async {
    final applications = await getUserApplications();

    if (status == 'all') {
      return applications;
    }

    return applications
        .where((app) => app['status'].toLowerCase() == status.toLowerCase())
        .toList();
  }

  // Helper method to fetch program details
  static Future<Map<String, dynamic>> _fetchProgramDetails(
      String programId) async {
    // IMPORTANT: Some Firestore rules allow direct doc reads but deny
    // collectionGroup queries. So collectionGroup lookups must not prevent
    // the original org-by-org doc lookup from running.

    // Attempt 1: collectionGroup lookup by documentId
    try {
      final programs = await FirebaseFirestore.instance
          .collectionGroup('programs')
          .where(FieldPath.documentId, isEqualTo: programId)
          .limit(1)
          .get();

      if (programs.docs.isNotEmpty) {
        final programDoc = programs.docs.first;
        final programData = programDoc.data();
        final orgIdFromPath = programDoc.reference.parent.parent?.id;
        final orgId =
            (programData['organizationId'] ?? orgIdFromPath ?? '').toString();

        Map<String, dynamic> orgData = const <String, dynamic>{};
        if (orgId.isNotEmpty) {
          final orgDoc = await FirebaseFirestore.instance
              .collection('organizations')
              .doc(orgId)
              .get();
          orgData = orgDoc.data() ?? const <String, dynamic>{};
        }

        final colorValue = programData['color'];
        final color = colorValue is int ? Color(colorValue) : Colors.blue[200]!;

        return {
          'id': programId,
          'programId': programId,
          'organizationId': orgId,
          'programName': programData['name'] ?? 'Unknown Program',
          'organizationName': orgData['name'] ?? 'Unknown Organization',
          'organizationLogo': Icons.business,
          'logoUrl': orgData['logoUrl'],
          'deadline': programData['deadline'] ?? 'No Deadline',
          'category': programData['category'] ?? 'Uncategorized',
          'categoryColor': color,
          'details': await _extractDetailsFromProgram(
            programData,
            orgData,
            orgId,
          ),
          'programStatus': programData['programStatus'] ?? 'Closed',
        };
      }
    } catch (e) {
      print('collectionGroup(documentId) lookup failed: $e');
    }

    // Attempt 2: collectionGroup lookup by stored `id` field
    try {
      final programs = await FirebaseFirestore.instance
          .collectionGroup('programs')
          .where('id', isEqualTo: programId)
          .limit(1)
          .get();

      if (programs.docs.isNotEmpty) {
        final programDoc = programs.docs.first;
        final programData = programDoc.data();
        final orgIdFromPath = programDoc.reference.parent.parent?.id;
        final orgId =
            (programData['organizationId'] ?? orgIdFromPath ?? '').toString();

        Map<String, dynamic> orgData = const <String, dynamic>{};
        if (orgId.isNotEmpty) {
          final orgDoc = await FirebaseFirestore.instance
              .collection('organizations')
              .doc(orgId)
              .get();
          orgData = orgDoc.data() ?? const <String, dynamic>{};
        }

        final colorValue = programData['color'];
        final color = colorValue is int ? Color(colorValue) : Colors.blue[200]!;

        return {
          'id': programId,
          'programId': programId,
          'organizationId': orgId,
          'programName': programData['name'] ?? 'Unknown Program',
          'organizationName': orgData['name'] ?? 'Unknown Organization',
          'organizationLogo': Icons.business,
          'logoUrl': orgData['logoUrl'],
          'deadline': programData['deadline'] ?? 'No Deadline',
          'category': programData['category'] ?? 'Uncategorized',
          'categoryColor': color,
          'details': await _extractDetailsFromProgram(
            programData,
            orgData,
            orgId,
          ),
          'programStatus': programData['programStatus'] ?? 'Closed',
        };
      }
    } catch (e) {
      print('collectionGroup(id field) lookup failed: $e');
    }

    // Attempt 3: original behavior (works with stricter rules)
    try {
      final orgSnapshot =
          await FirebaseFirestore.instance.collection('organizations').get();

      for (final orgDoc in orgSnapshot.docs) {
        final orgId = orgDoc.id;
        final orgData = orgDoc.data();

        final programDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('programs')
            .doc(programId)
            .get();

        if (!programDoc.exists) continue;
        final programData = programDoc.data();
        if (programData == null) continue;

        final colorValue = programData['color'];
        final color = colorValue is int ? Color(colorValue) : Colors.blue[200]!;

        return {
          'id': programId,
          'programId': programId,
          'organizationId': orgId,
          'programName': programData['name'] ?? 'Unknown Program',
          'organizationName': orgData['name'] ?? 'Unknown Organization',
          'organizationLogo': Icons.business,
          'logoUrl': orgData['logoUrl'],
          'deadline': programData['deadline'] ?? 'No Deadline',
          'category': programData['category'] ?? 'Uncategorized',
          'categoryColor': color,
          'details': await _extractDetailsFromProgram(
            programData,
            orgData,
            orgId,
          ),
          'programStatus': programData['programStatus'] ?? 'Closed',
        };
      }
    } catch (e) {
      print('org-by-org lookup failed: $e');
    }

    return <String, dynamic>{};
  }

  // Helper method to extract structured details from a program
  static Future<Map<String, dynamic>> _extractDetailsFromProgram(
    Map<String, dynamic> programData,
    Map<String, dynamic> orgData,
    String orgId,
  ) async {
    // Extract description from detail sections
    String description = '';
    List<String> requirements = [];
    List<String> eligibilityPoints = [];

    if (programData['detailSections'] != null) {
      final typedDetailSections =
          ResponseSection.listFromDynamic(programData['detailSections']);

      for (final section in typedDetailSections) {
        switch (section) {
          case ParagraphResponseSection():
            final label = section.label.toLowerCase();
            if (section.label == 'Description' ||
                label.contains('description')) {
              description = section.content;
            }
            break;
          case ListResponseSection():
            final label = section.label.toLowerCase();
            if (section.label == 'Requirements' ||
                label.contains('requirement')) {
              requirements = section.items;
            }
            if (section.label == 'Eligibility' || label.contains('eligible')) {
              eligibilityPoints = section.items;
            }
            break;
          case AttachmentResponseSection():
            break;
        }
      }
    }

    return {
      'description': description,
      'requirements': requirements,
      'eligibility': {
        'points': eligibilityPoints,
        'extra': '',
      },
      'forms': ProgramFormField.listFromDynamic(programData['formFields']),
    };
  }
}
