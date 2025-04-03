import 'package:flutter/material.dart';

class AvailableApplicationsData {
  static List<Map<String, dynamic>> getAllApplications() {
    return [
      {
        'category': 'Education',
        'programName': 'DOST Science Scholarship',
        'organizationName': 'Department of Science and Technology',
        'description': 'Scholarship for students pursuing degrees in science and technology fields.',
        'deadline': 'Dec 31, 2023',
        'categoryColor': Colors.blue[200],
        'organizationLogo': Icons.school,
      },
      {
        'category': 'Education',
        'programName': 'Public School Teachers Grant',
        'organizationName': 'Department of Education',
        'description': 'Financial assistance program for public school teachers pursuing advanced studies.',
        'deadline': 'Jan 15, 2024',
        'categoryColor': Colors.blue[200],
        'organizationLogo': Icons.school,
      },
      {
        'category': 'Healthcare',
        'programName': 'Medical Technology Scholarship',
        'organizationName': 'Department of Health',
        'description': 'Scholarship program for aspiring medical technologists.',
        'deadline': 'Dec 20, 2023',
        'categoryColor': Colors.green[200],
        'organizationLogo': Icons.local_hospital,
      },
      {
        'category': 'Social',
        'programName': 'Youth Leadership Program',
        'organizationName': 'Department of Social Welfare',
        'description': 'Training and support program for young community leaders.',
        'deadline': 'Jan 20, 2024',
        'categoryColor': Colors.purple[200],
        'organizationLogo': Icons.people,
      },
    ];
  }

  static List<Map<String, dynamic>> getApplicationsByCategory(String category) {
    return getAllApplications()
        .where((app) => app['category'] == category)
        .toList();
  }
}
