import 'package:flutter/material.dart';
import '../data/application_data.dart';
import '../data/available_applications_data.dart';
import '../pages/application_form_page.dart';
import '../pages/application_pending_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'application_complete_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[850],
        appBar: AppBar(
          toolbarHeight: 100, // Add this to increase AppBar height
          title: Padding(
            padding:
                EdgeInsets.symmetric(vertical: 16), // Reduced from 100 to 16
            child: Text(
              'My Applications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[200],
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.grey[850],
          bottom: TabBar(
            tabs: ['All', 'Ongoing', 'Pending', 'Completed'] // Swapped order
                .map((e) => Tab(
                      child: Container(
                        width: 80, // Fixed width for each tab
                        child: Text(
                          e,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[200],
                          ),
                        ),
                      ),
                    ))
                .toList(),
            labelStyle: TextStyle(
              fontSize: 14, // Reduced font size
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelColor: Colors.grey[600],
            labelColor: Colors.grey[200],
            dividerColor: Colors
                .transparent, // Add this to remove the grey separator line
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 2.0,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(
                horizontal: 0, vertical: 4), // Reduced padding
            isScrollable: false, // Force tabs to be evenly distributed
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: TabBarView(
            children: [
              ApplicationList(status: 'all'),
              ApplicationList(status: 'ongoing'), // Swapped order
              ApplicationList(status: 'pending'),
              ApplicationList(status: 'completed'),
            ],
          ),
        ),
      ),
    );
  }
}

class ApplicationList extends StatefulWidget {
  final String status;

  const ApplicationList({super.key, required this.status});

  @override
  State<ApplicationList> createState() => _ApplicationListState();
}

class _ApplicationListState extends State<ApplicationList> {
  Future<List<Map<String, dynamic>>>? _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() {
    _applicationsFuture =
        ApplicationData.getApplicationsByStatus(widget.status);
  }

  void refreshList() {
    setState(() {
      _loadApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _applicationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text('Error loading applications: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No applications found'));
        }

        final applications = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) => ApplicationCard(
            application: applications[index],
            onRefresh: refreshList,
          ),
          itemCount: applications.length,
        );
      },
    );
  }
}

class ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;
  final VoidCallback onRefresh;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = application['categoryColor'];
    final Color lightColor = baseColor.withOpacity(0.15);

    return InkWell(
      onTap: () async {
        // Get the current user
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('You must be signed in to access this application')),
          );
          return;
        }

        final currentStatus = application['status'] ?? 'Unknown';

        Widget destinationPage;
        if (currentStatus == 'Pending') {
          destinationPage = ApplicationPendingPage(application: application);
        } else if (currentStatus == 'Completed') {
          destinationPage = ApplicationCompletePage(application: application);
        } else {
          destinationPage = ApplicationFormPage(application: application);
        }

        // Get the result from navigation and refresh if needed
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationPage),
        );

        // If we got a refresh signal, refresh the list
        if (result == true) {
          onRefresh();
        }
      },
      child: Container(
        margin:
            EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Reduced from 8
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[500]!,
            width: 1, // Increased from 1.0 (default) to 1.5
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(14), // Reduced from 16
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and organization name
                  Row(
                    children: [
                      // Replace Icon with Image container
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: application['logoUrl'] != null &&
                                  application['logoUrl'].toString().isNotEmpty
                              ? Image.network(
                                  application['logoUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.business,
                                      size: 18,
                                      color: Colors.grey[800],
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.business,
                                  size: 18,
                                  color: Colors.grey[800],
                                ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        application['organizationName'] ?? 'Organization',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10), // Reduced from 12

                  // Application title
                  Text(
                    application['programName'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 10), // Reduced from 12

                  // Status and deadline
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          application['status'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 13), // Reduced spacing
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Due on    ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            TextSpan(
                              text: application['deadline'],
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10), // Reduced from 12

                  // Progress section
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.start, // Changed from spaceBetween
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: List.generate(3, (index) {
                      final int segmentProgress;

                      if (application['status'] == 'Ongoing') {
                        segmentProgress = 1;
                      } else if (application['status'] == 'Pending') {
                        segmentProgress = 2;
                      } else if (application['status'] == 'Completed') {
                        segmentProgress = 3;
                      } else {
                        segmentProgress = 0;
                      }

                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          height: 4,
                          decoration: BoxDecoration(
                            color: index < segmentProgress
                                ? Colors.grey[600]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Footer - Replace InkWell with Container
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(11),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.grey[200],
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
