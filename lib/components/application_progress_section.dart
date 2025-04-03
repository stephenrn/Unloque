import 'package:flutter/material.dart';
import '../data/application_data.dart';
import 'application_progress_card.dart';

class ApplicationProgressSection extends StatelessWidget {
  const ApplicationProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final applications = ApplicationData.getSampleApplications();

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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: Size(0, 25),
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
          height: 180,
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
                categoryColor: app['categoryColor'] as Color,
                organizationLogo: app['organizationLogo'] as IconData,
              );
            },
          ),
        ),
      ],
    );
  }
}
