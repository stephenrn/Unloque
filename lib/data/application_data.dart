import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'available_applications_data.dart';

class ApplicationData {
  static Future<List<Map<String, dynamic>>> getUserApplications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('users-application')
        .get();

    final availableApplications =
        AvailableApplicationsData.getAllApplications();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final applicationDetails = availableApplications.firstWhere(
        (app) => app['id'] == data['id'],
        orElse: () => {}, // Return an empty map instead of null
      );

      return {
        'id': data['id'] ?? 'Unknown ID', // Handle null id
        'status': data['status'] ?? 'Unknown', // Handle null status
        'programName': applicationDetails['programName'] ??
            'Unknown Program', // Handle null programName
        'organizationName': applicationDetails['organizationName'] ??
            'Unknown Organization', // Handle null organizationName
        'category':
            applicationDetails['category'] ?? 'Unknown', // Handle null category
        'deadline': applicationDetails['deadline'] ??
            'No Deadline', // Handle null deadline
        'categoryColor': applicationDetails['categoryColor'] ??
            Colors.grey, // Handle null categoryColor
        'organizationLogo': applicationDetails['organizationLogo'] ??
            Icons.help_outline, // Handle null organizationLogo
        ...?applicationDetails,
      };
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getApplicationsByStatus(
      String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('users-application')
        .get();

    final availableApplications =
        AvailableApplicationsData.getAllApplications();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          final applicationDetails = availableApplications.firstWhere(
            (app) => app['id'] == data['id'],
            orElse: () => {}, // Return an empty map instead of null
          );

          return {
            'id': data['id'] ?? 'Unknown ID', // Handle null id
            'status': data['status'] ?? 'Unknown', // Handle null status
            'programName': applicationDetails['programName'] ??
                'Unknown Program', // Handle null programName
            'organizationName': applicationDetails['organizationName'] ??
                'Unknown Organization', // Handle null organizationName
            'category': applicationDetails['category'] ??
                'Unknown', // Handle null category
            'deadline': applicationDetails['deadline'] ??
                'No Deadline', // Handle null deadline
            'categoryColor': applicationDetails['categoryColor'] ??
                Colors.grey, // Handle null categoryColor
            'organizationLogo': applicationDetails['organizationLogo'] ??
                Icons.help_outline, // Handle null organizationLogo
            ...?applicationDetails,
          };
        })
        .where((app) =>
            status == 'all' ||
            app['status'].toLowerCase() == status.toLowerCase())
        .toList();
  }
}
