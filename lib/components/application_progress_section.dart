import 'package:flutter/material.dart';
import '../data/application_data.dart';
import 'application_progress_card.dart';

class ApplicationProgressSection extends StatefulWidget {
  const ApplicationProgressSection({super.key});

  @override
  ApplicationProgressSectionState createState() =>
      ApplicationProgressSectionState();
}

class ApplicationProgressSectionState
    extends State<ApplicationProgressSection> {
  Future<void> refreshApplications() async {
    setState(() {});
  }

  Future<void> fetchAdditionalData() async {
    // Logic to fetch and process additional data
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ApplicationData.getUserApplications(
          'user-id'), // Replace with actual user ID from authentication
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading applications'));
        } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(child: Text('No applications found'));
        }

        final applications = snapshot.data as List;

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
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
                    category: app['category'],
                    programName: app['programName'],
                    deadline: app['deadline'],
                    status: app['status'],
                    categoryColor: app['categoryColor'],
                    organizationLogo: app['organizationLogo'],
                    organizationName: app['organizationName'],
                    id: app['id'],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
