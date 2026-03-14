import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unloque/pages/admin/organization_response_builder.dart';

class ApplicationManagerPage extends StatefulWidget {
  final String organizationId;
  final String programId;
  final String programName;
  final Color categoryColor;

  const ApplicationManagerPage({
    Key? key,
    required this.organizationId,
    required this.programId,
    required this.programName,
    required this.categoryColor,
  }) : super(key: key);

  @override
  State<ApplicationManagerPage> createState() => _ApplicationManagerPageState();
}

class _ApplicationManagerPageState extends State<ApplicationManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchApplications(
      List<QueryDocumentSnapshot> users) async {
    List<Map<String, dynamic>> applications = [];
    for (var userDoc in users) {
      final userId = userDoc.id;
      final userEmail = userDoc['email'] ?? '';
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('users-application')
          .where('id', isEqualTo: widget.programId)
          .get();
      for (var doc in query.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['userId'] = userId;
        data['userEmail'] = userEmail;
        applications.add(data);
      }
    }
    return applications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              // Back button
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  icon: Transform.rotate(
                    angle: 4.71239,
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              // Page title
              Expanded(
                child: Center(
                  child: Text(
                    'Application Manager',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 28),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.grey[800],
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData) {
            return Center(child: Text('No users found.'));
          }
          final users = userSnapshot.data!.docs;
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchApplications(users),
            builder: (context, appSnapshot) {
              if (appSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!appSnapshot.hasData) {
                return Center(child: Text('No applications submitted yet.'));
              }
              final allApplications = appSnapshot.data!;
              final pendingApps = allApplications
                  .where((app) =>
                      (app['status']?.toString().toLowerCase() ?? '') ==
                      'pending')
                  .toList();
              final completedApps = allApplications
                  .where((app) =>
                      (app['status']?.toString().toLowerCase() ?? '') ==
                      'completed')
                  .toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildApplicationList(
                      context, pendingApps, 'No pending applications.'),
                  _buildApplicationList(
                      context, completedApps, 'No completed applications.'),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildApplicationList(BuildContext context,
      List<Map<String, dynamic>> applications, String emptyText) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              emptyText,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final app = applications[index];
        final userId = (app['userId'] ?? '').toString();
        final userEmail = (app['userEmail'] ?? '').toString();
        final status = (app['status'] ?? '').toString();
        String submittedAt = '-';
        final ts = app['submittedAt'] ?? app['createdAt'];
        if (ts != null) {
          try {
            if (ts is Timestamp) {
              submittedAt = ts.toDate().toString().split(' ')[0];
            } else if (ts is DateTime) {
              submittedAt = ts.toString().split(' ')[0];
            } else if (ts is String && ts.length >= 10) {
              submittedAt = ts.substring(0, 10);
            }
          } catch (_) {}
        }

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrganizationResponseBuilderPage(
                    application: {
                      ...app,
                      'programId': widget.programId,
                      'organizationId': widget.organizationId,
                    },
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Icon(Icons.person, color: Colors.grey[800]),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userEmail.isNotEmpty ? userEmail : userId,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'User ID: $userId',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Submitted: $submittedAt',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: status.toLowerCase() == 'pending'
                          ? Colors.amber[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: status.toLowerCase() == 'pending'
                            ? Colors.amber[800]
                            : Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
