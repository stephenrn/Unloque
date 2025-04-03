import 'package:flutter/material.dart';

class ApplicationData {
  static List<Map<String, dynamic>> getSampleApplications() {
    return [
      {
        'category': 'Education',
        'programName': 'CHED Merit Scholarship Program',
        'organizationName': 'Commission on Higher Education',
        'deadline': 'Dec 31, 2023',
        'status': 'Ongoing',
        'categoryColor': Colors.blue[200],
        'organizationLogo': Icons.school,
      },
      {
        'category': 'Education',
        'programName': 'DepEd Teachers Scholarship',
        'organizationName': 'Department of Education',
        'deadline': 'Jan 15, 2024',
        'status': 'Pending',
        'categoryColor': Colors.blue[200],
        'organizationLogo': Icons.school,
      },
      {
        'category': 'Healthcare',
        'programName': 'DOH Medical Scholarship',
        'organizationName': 'Department of Health',
        'deadline': 'Dec 20, 2023',
        'status': 'Ongoing',
        'categoryColor': Colors.green[200],
        'organizationLogo': Icons.local_hospital,
      },
      {
        'category': 'Healthcare',
        'programName': 'Provincial Health Grant',
        'organizationName': 'Provincial Health Office',
        'deadline': 'Jan 5, 2024',
        'status': 'Completed',
        'categoryColor': Colors.green[200],
        'organizationLogo': Icons.local_hospital,
      },
      {
        'category': 'Social',
        'programName': 'DSWD Youth Development',
        'organizationName': 'Department of Social Welfare',
        'deadline': 'Dec 25, 2023',
        'status': 'Pending',
        'categoryColor': Colors.purple[200],
        'organizationLogo': Icons.people,
      },
      {
        'category': 'Social',
        'programName': 'Community Leadership Grant',
        'organizationName': 'Local Government Unit',
        'deadline': 'Jan 20, 2024',
        'status': 'Ongoing',
        'categoryColor': Colors.purple[200],
        'organizationLogo': Icons.people,
      },
    ];
  }

  static List<Map<String, dynamic>> getApplicationsByStatus(String status) {
    final allApplications = getSampleApplications();
    
    if (status.toLowerCase() == 'all') {
      return allApplications;
    }
    
    return allApplications.where((app) => 
      app['status'].toString().toLowerCase() == status.toLowerCase()
    ).toList();
  }
}
