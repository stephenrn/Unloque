import 'package:flutter/material.dart';
import 'application_progress_card.dart';

class ApplicationProgressSection extends StatelessWidget {
  const ApplicationProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data - replace with real data later
    final applications = [
      {
        'category': 'Education',
        'programName': 'CHED Merit Scholarship Program',
        'deadline': 'Dec 31, 2023',
        'status': 'Ongoing',
        'progress': 65.0,
        'categoryColor': Colors.purple[200],
        'organizationLogo': Icons.school, // Added organization logo
      },
      {
        'category': 'Healthcare',
        'programName': 'Medical Student Grant',
        'deadline': 'Jan 15, 2024',
        'status': 'Pending',
        'progress': 25.0,
        'categoryColor': Colors.cyan[400],
        'organizationLogo': Icons.local_hospital, // Added organization logo
      },
      {
        'category': 'Technology',
        'programName': 'DICT Tech Training Program',
        'deadline': 'Dec 20, 2023',
        'status': 'Approved',
        'progress': 85.0,
        'categoryColor': Colors.green[300],
        'organizationLogo': Icons.computer, // Added organization logo
      },
      {
        'category': 'Agriculture',
        'programName': 'DA Young Farmers Program',
        'deadline': 'Jan 5, 2024',
        'status': 'Ongoing',
        'progress': 45.0,
        'categoryColor': Colors.blue[300]!,
        'organizationLogo': Icons.agriculture, // Added organization logo
      },
      {
        'category': 'Business',
        'programName': 'DTI SME Development',
        'deadline': 'Dec 25, 2023',
        'status': 'Pending',
        'progress': 15.0,
        'categoryColor': Colors.orange[300],
        'organizationLogo': Icons.business, // Added organization logo
      },
    ];

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'You Have ${applications.length} In Progress Applications',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[100],
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all applications
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Reduced vertical padding from 1 to 0
                  minimumSize: Size(0, 25), // Added to control minimum height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Show All',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180, // Reduced from 200
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return ApplicationProgressCard(
                category: app['category'] as String,
                programName: app['programName'] as String,
                deadline: app['deadline'] as String,
                status: app['status'] as String,
                progress: app['progress'] as double,
                categoryColor: app['categoryColor'] as Color,
                organizationLogo: app['organizationLogo'] as IconData, // Added this line
              );
            },
          ),
        ),
      ],
    );
  }
}
