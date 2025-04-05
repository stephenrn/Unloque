import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'available_applications_data.dart';

class ApplicationData {
  static Future<List<Map<String, dynamic>>> getUserApplications(
      String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('applications')
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
        'id': data['id'],
        'status': data['status'],
        ...?applicationDetails,
      };
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getApplicationsByStatus(
      String userId, String status) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('applications')
        .where('status', isEqualTo: status == 'all' ? null : status)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'category': data['category'],
        'programName': data['programName'],
        'organizationName': data['organizationName'],
        'deadline': data['deadline'],
        'status': data['status'],
        'categoryColor': Color(data['categoryColor']),
        'organizationLogo':
            IconData(data['organizationLogo'], fontFamily: 'MaterialIcons'),
      };
    }).toList();
  }
}
