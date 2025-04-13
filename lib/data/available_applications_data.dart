import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableApplicationsData {
  // Cache for program data to reduce Firebase reads
  static Map<String, dynamic> _programCache = {};
  static Map<String, List<Map<String, dynamic>>> _categoryCache = {};

  // Get program data by ID - returns Future for async operation
  static Future<Map<String, dynamic>> getApplicationById(
      String programId) async {
    // Check if program is in cache
    if (_programCache.containsKey(programId)) {
      return _programCache[programId];
    }

    try {
      // Since we don't know which organization this program belongs to,
      // we need to query across all organizations
      final QuerySnapshot orgSnapshot =
          await FirebaseFirestore.instance.collection('organizations').get();

      for (final orgDoc in orgSnapshot.docs) {
        final String orgId = orgDoc.id;
        final orgData = orgDoc.data() as Map<String, dynamic>;

        // Query for the specific program in this organization
        final programDoc = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('programs')
            .doc(programId)
            .get();

        if (programDoc.exists) {
          final programData = programDoc.data() as Map<String, dynamic>;

          // Convert to our application format
          final application = _convertToApplicationFormat(
            programData,
            orgData,
            orgId,
          );

          // Cache the data
          _programCache[programId] = application;
          return application;
        }
      }

      // If program not found
      return {};
    } catch (e) {
      print('Error fetching program by ID: $e');
      return {};
    }
  }

  // Get all available applications
  static Future<List<Map<String, dynamic>>> getAllApplications() async {
    try {
      List<Map<String, dynamic>> allApplications = [];

      // Get all organizations
      final QuerySnapshot orgSnapshot =
          await FirebaseFirestore.instance.collection('organizations').get();

      // For each organization, get all programs
      for (final orgDoc in orgSnapshot.docs) {
        final String orgId = orgDoc.id;
        final orgData = orgDoc.data() as Map<String, dynamic>;

        final QuerySnapshot programsSnapshot = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('programs')
            .where('programStatus', isEqualTo: 'Open') // Only get Open programs
            .get();

        // Convert each program to our application format
        for (final programDoc in programsSnapshot.docs) {
          final programData = programDoc.data() as Map<String, dynamic>;

          final application = _convertToApplicationFormat(
            programData,
            orgData,
            orgId,
          );

          allApplications.add(application);

          // Cache individual program
          _programCache[programData['id']] = application;
        }
      }

      return allApplications;
    } catch (e) {
      print('Error fetching all applications: $e');
      return [];
    }
  }

  // Get applications by category
  static Future<List<Map<String, dynamic>>> getApplicationsByCategory(
      String category) async {
    // Check if category is in cache
    if (_categoryCache.containsKey(category)) {
      return _categoryCache[category]!;
    }

    try {
      List<Map<String, dynamic>> categoryApplications = [];

      // Get all organizations
      final QuerySnapshot orgSnapshot =
          await FirebaseFirestore.instance.collection('organizations').get();

      // For each organization, get programs matching the category
      for (final orgDoc in orgSnapshot.docs) {
        final String orgId = orgDoc.id;
        final orgData = orgDoc.data() as Map<String, dynamic>;

        final QuerySnapshot programsSnapshot = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('programs')
            .where('category', isEqualTo: category)
            .where('programStatus', isEqualTo: 'Open') // Only get Open programs
            .get();

        // Convert each program to our application format
        for (final programDoc in programsSnapshot.docs) {
          final programData = programDoc.data() as Map<String, dynamic>;

          final application = _convertToApplicationFormat(
            programData,
            orgData,
            orgId,
          );

          categoryApplications.add(application);

          // Cache individual program
          _programCache[programData['id']] = application;
        }
      }

      // Cache the category results
      _categoryCache[category] = categoryApplications;

      return categoryApplications;
    } catch (e) {
      print('Error fetching applications by category: $e');
      return [];
    }
  }

  // Helper method to convert Firestore data to application format
  static Map<String, dynamic> _convertToApplicationFormat(
    Map<String, dynamic> programData,
    Map<String, dynamic> orgData,
    String orgId,
  ) {
    return {
      'id': programData['id'],
      'category': programData['category'] ?? 'Uncategorized',
      'programName': programData['name'] ?? 'Unnamed Program',
      'organizationName': orgData['name'] ?? 'Unnamed Organization',
      'description': programData['description'] ?? '',
      'deadline': programData['deadline'] ?? 'No Deadline',
      'categoryColor':
          Color(programData['color'] ?? 0xFFB3E5FC), // Default light blue
      'organizationLogo': Icons.business, // Keep default icon for type safety
      'logoUrl': orgData['logoUrl'], // Add the logo URL field
      'organizationId': orgId,
      'programStatus': programData['programStatus'] ?? 'Closed',
      'details': {
        'description': _getDescriptionFromDetailSections(
            programData['detailSections'] ?? []),
        'requirements': _getRequirementsFromDetailSections(
            programData['detailSections'] ?? []),
        'eligibility': {
          'points': _getEligibilityFromDetailSections(
              programData['detailSections'] ?? []),
          'extra': '',
        },
        'forms': programData['formFields'] ?? [],
        'detailSections':
            programData['detailSections'] ?? [], // Include detailSections
      },
    };
  }

  // Extract description from detail sections
  static String _getDescriptionFromDetailSections(
      List<dynamic> detailSections) {
    for (var section in detailSections) {
      if (section['type'] == 'paragraph' &&
          (section['label'] == 'Description' ||
              section['label']
                  .toString()
                  .toLowerCase()
                  .contains('description'))) {
        return section['content'] ?? '';
      }
    }
    return '';
  }

  // Extract requirements from detail sections
  static List<String> _getRequirementsFromDetailSections(
      List<dynamic> detailSections) {
    for (var section in detailSections) {
      if (section['type'] == 'list' &&
          (section['label'] == 'Requirements' ||
              section['label']
                  .toString()
                  .toLowerCase()
                  .contains('requirement'))) {
        return List<String>.from(section['items'] ?? []);
      }
    }
    return ['No requirements specified'];
  }

  // Extract eligibility from detail sections
  static List<String> _getEligibilityFromDetailSections(
      List<dynamic> detailSections) {
    for (var section in detailSections) {
      if (section['type'] == 'list' &&
          (section['label'] == 'Eligibility' ||
              section['label'].toString().toLowerCase().contains('eligible'))) {
        return List<String>.from(section['items'] ?? []);
      }
    }
    return ['No eligibility criteria specified'];
  }

  // Clear cache
  static void clearCache() {
    _programCache.clear();
    _categoryCache.clear();
  }
}
