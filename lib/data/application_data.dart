import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplicationData {
  // Get all user applications with full details
  static Future<List<Map<String, dynamic>>> getUserApplications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    try {
      // Get all applications for this user
      final userAppSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
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
        final programId = appData['id'];

        // Get the organization that owns this program
        final programDetails = await _fetchProgramDetails(programId);

        if (programDetails.isNotEmpty) {
          userApplications.add({
            ...programDetails,
            'status': appData['status'] ?? 'Unknown',
            // Add any other application-specific fields from the user's application document
            ...appData,
          });
        }
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
    try {
      // Query across all organizations to find the program
      final QuerySnapshot orgSnapshot =
          await FirebaseFirestore.instance.collection('organizations').get();

      for (final orgDoc in orgSnapshot.docs) {
        final String orgId = orgDoc.id;
        final orgData = orgDoc.data() as Map<String, dynamic>;

        final programDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('programs')
            .doc(programId)
            .get();

        if (programDoc.exists) {
          final programData = programDoc.data() as Map<String, dynamic>;

          // Extract details from the program document
          final color = programData['color'] != null
              ? Color(programData['color'])
              : Colors.blue[200]!;

          return {
            'id': programId,
            'programName': programData['name'] ?? 'Unknown Program',
            'organizationName': orgData['name'] ?? 'Unknown Organization',
            'organizationLogo':
                Icons.business, // Keep default icon for type safety
            'logoUrl': orgData['logoUrl'], // Add the logo URL
            'deadline': programData['deadline'] ?? 'No Deadline',
            'category': programData['category'] ?? 'Uncategorized',
            'categoryColor': color,
            'details':
                await _extractDetailsFromProgram(programData, orgData, orgId),
            'programStatus': programData['programStatus'] ?? 'Closed',
          };
        }
      }

      return {};
    } catch (e) {
      print('Error fetching program details: $e');
      return {};
    }
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
      final detailSections = programData['detailSections'] as List<dynamic>;

      for (final section in detailSections) {
        if (section['type'] == 'paragraph' &&
            (section['label'] == 'Description' ||
                section['label']
                    .toString()
                    .toLowerCase()
                    .contains('description'))) {
          description = section['content'] ?? '';
        }

        if (section['type'] == 'list' &&
            (section['label'] == 'Requirements' ||
                section['label']
                    .toString()
                    .toLowerCase()
                    .contains('requirement'))) {
          requirements = List<String>.from(section['items'] ?? []);
        }

        if (section['type'] == 'list' &&
            (section['label'] == 'Eligibility' ||
                section['label']
                    .toString()
                    .toLowerCase()
                    .contains('eligible'))) {
          eligibilityPoints = List<String>.from(section['items'] ?? []);
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
      'forms': programData['formFields'] ?? [],
    };
  }
}
