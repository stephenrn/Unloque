import 'package:flutter/material.dart';
import '../data/application_data.dart';
import 'application_progress_card.dart';
import '../pages/home_page.dart';

class ApplicationProgressSection extends StatefulWidget {
  final Function? scrollToCategories; // Add this parameter to handle scrolling

  const ApplicationProgressSection({super.key, this.scrollToCategories});

  @override
  ApplicationProgressSectionState createState() =>
      ApplicationProgressSectionState();
}

class ApplicationProgressSectionState
    extends State<ApplicationProgressSection> {
  // Track if we need to refresh
  bool _needsRefresh = true;
  List? _cachedApplications;

  Future<void> refreshApplications() async {
    // Force a refresh by clearing cache and marking as needing refresh
    setState(() {
      _cachedApplications = null;
      _needsRefresh = true;
    });
  }

  Future<List> _loadApplications() async {
    if (_cachedApplications != null && !_needsRefresh) {
      return _cachedApplications!;
    }

    final applications = await ApplicationData.getUserApplications();
    _cachedApplications = applications;
    _needsRefresh = false;
    return applications;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 220, // Consistent height for loading state
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    'Loading your applications...',
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            height: 220, // Consistent height for error state
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 40, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    'Error loading applications',
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Container(
            height: 220, // Consistent height for empty state
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open, size: 40, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    'No applications found',
                    style: TextStyle(color: Colors.grey[300], fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Apply now in programs in the category section',
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  IconButton(
                    onPressed: () {
                      if (widget.scrollToCategories != null) {
                        widget.scrollToCategories!();
                      }
                    },
                    icon: Icon(
                      Icons.arrow_downward_rounded,
                      color: Colors.grey[300],
                      size: 28,
                    ),
                    padding: EdgeInsets.all(8),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Colors.grey[800],
                      ),
                      shape: MaterialStateProperty.all(CircleBorder()),
                    ),
                  ),
                ],
              ),
            ),
          );
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
                      // Navigate to History tab (index 2) in the bottom navigation bar
                      HomePage.navigateToTab(context, 2);
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
                    category:
                        app['category'] ?? 'Unknown', // Handle null category
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
