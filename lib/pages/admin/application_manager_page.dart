import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unloque/pages/application_pending_page.dart';

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

class _ApplicationManagerPageState extends State<ApplicationManagerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submitted Applications'),
        backgroundColor: widget.categoryColor,
        foregroundColor: Colors.white,
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
              if (!appSnapshot.hasData || appSnapshot.data!.isEmpty) {
                return Center(child: Text('No applications submitted yet.'));
              }
              final applications = appSnapshot.data!
                  .where((app) =>
                      (app['status']?.toString().toLowerCase() ?? '') !=
                      'ongoing')
                  .toList();
              return ListView.separated(
                itemCount: applications.length,
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (context, index) {
                  final app = applications[index];
                  final userId = (app['userId'] ?? '').toString();
                  final userEmail = (app['userEmail'] ?? '').toString();
                  final status = (app['status'] ?? '').toString();
                  // Submission date: try 'submittedAt' (Timestamp), fallback to 'createdAt', else '-'
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

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.person, color: Colors.grey[800]),
                    ),
                    title: Text(userEmail.isNotEmpty ? userEmail : userId),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User ID: $userId',
                            style: TextStyle(fontSize: 12)),
                        Text('Submitted: $submittedAt',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Text(status),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ApplicationPendingPage(
                            application: {
                              ...app,
                              'programId': widget.programId,
                              'organizationId': widget.organizationId,
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchApplications(
      List<QueryDocumentSnapshot> users) async {
    List<Map<String, dynamic>> applications = [];
    for (var userDoc in users) {
      final userId = userDoc.id;
      final userEmail = userDoc['email'] ?? '';
      // Fix: Query by 'id' (the program id) instead of 'programId'
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
}
