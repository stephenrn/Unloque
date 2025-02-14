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
        'categoryColor': Colors.purple,
      },
      {
        'category': 'Healthcare',
        'programName': 'Medical Student Grant',
        'deadline': 'Jan 15, 2024',
        'status': 'Pending',
        'progress': 25.0,
        'categoryColor': Colors.green,
      },
      {
        'category': 'Technology',
        'programName': 'DICT Tech Training Program',
        'deadline': 'Dec 20, 2023',
        'status': 'Approved',
        'progress': 85.0,
        'categoryColor': Colors.blue,
      },
      {
        'category': 'Agriculture',
        'programName': 'DA Young Farmers Program',
        'deadline': 'Jan 5, 2024',
        'status': 'Ongoing',
        'progress': 45.0,
        'categoryColor': Colors.green[700]!,
      },
      {
        'category': 'Business',
        'programName': 'DTI SME Development',
        'deadline': 'Dec 25, 2023',
        'status': 'Pending',
        'progress': 15.0,
        'categoryColor': Colors.orange,
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[100],
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all applications
                },
                child: Row(
                  children: [
                    Text(
                      'Show All',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.blue[700],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170, // Increased from 150
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
              );
            },
          ),
        ),
      ],
    );
  }
}
