import 'package:flutter/material.dart';
import '../data/application_data.dart';
import 'application_progress_card.dart';
import '../pages/home_page.dart'; // Add import for HomePage

class ApplicationProgressSection extends StatefulWidget {
  const ApplicationProgressSection({super.key});

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
    return Container(
      // Add a fixed height to ensure the container doesn't resize
      constraints: BoxConstraints(minHeight: 230),
      child: FutureBuilder(
        future: _loadApplications(),
        builder: (context, snapshot) {
          return Column(
            children: [
              // Always show the header row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      snapshot.hasData && (snapshot.data as List).isNotEmpty
                          ? 'You Have ${(snapshot.data as List).length} In Progress Applications'
                          : 'No Applications In Progress',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[100],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
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

              // Always include the SizedBox with consistent height
              SizedBox(
                height: 180,
                child: snapshot.connectionState == ConnectionState.waiting
                    ? Center(child: CircularProgressIndicator())
                    : snapshot.hasError
                        ? Center(
                            child: Text('Error loading applications',
                                style: TextStyle(color: Colors.grey[100])))
                        : (!snapshot.hasData || (snapshot.data as List).isEmpty)
                            ? Center(
                                child: Text('No applications found',
                                    style: TextStyle(color: Colors.grey[100])))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                itemCount: (snapshot.data as List).length,
                                itemBuilder: (context, index) {
                                  final app = (snapshot.data as List)[index];
                                  return ApplicationProgressCard(
                                    category: app['category'] ??
                                        'Unknown', // Handle null category
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
      ),
    );
  }
}
