import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/application_progress_card.dart';
import '../data/application_data.dart'; // Import the updated data source

class ApplicationProgressSection extends StatefulWidget {
  final VoidCallback scrollToCategories;

  const ApplicationProgressSection({
    Key? key,
    required this.scrollToCategories,
  }) : super(key: key);

  @override
  ApplicationProgressSectionState createState() =>
      ApplicationProgressSectionState();
}

class ApplicationProgressSectionState
    extends State<ApplicationProgressSection> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  // Method to refresh the applications list
  Future<void> refreshApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    _loadApplications();
  }

  // Load applications from Firebase
  Future<void> _loadApplications() async {
    try {
      // Check if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _applications = [];
        });
        return;
      }

      // Get all user applications from Firebase
      final applications = await ApplicationData.getUserApplications();

      // Update state with loaded applications
      setState(() {
        _isLoading = false;
        _applications = applications;
      });
    } catch (e) {
      print('Error loading applications: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load applications';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate application counts by status
    final ongoingApplications =
        _applications.where((app) => app['status'] == 'Ongoing').toList();
    final pendingApplications =
        _applications.where((app) => app['status'] == 'Pending').toList();
    final completedApplications =
        _applications.where((app) => app['status'] == 'Completed').toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Ensure left alignment
        children: [
          // Title and view button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'In Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: widget.scrollToCategories,
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 17,
                ),
                label: const Text(
                  'Find Programs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Applications section
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            )
          else if (_applications.isEmpty)
            // Center the empty state content horizontally
            Container(
              width: double.infinity, // Take full width
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center children horizontally
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    Icons.folder_outlined,
                    size: 48,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No applications in progress',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                  ),
                  Text(
                    'Tap Find Programs to get started',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          else
            // Increase the height significantly to accommodate the cards
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Ensure left alignment
                  mainAxisAlignment:
                      MainAxisAlignment.start, // Start from the left
                  children: [
                    ...ongoingApplications.map(
                      (app) => ApplicationProgressCard(
                        id: app['id'] ?? '',
                        category: app['category'] ?? 'Unknown',
                        programName: app['programName'] ?? 'Unknown Program',
                        deadline: app['deadline'] ?? 'No Deadline',
                        status: app['status'] ?? 'Unknown',
                        categoryColor: app['categoryColor'] ?? Colors.grey,
                        organizationLogo:
                            app['organizationLogo'] ?? Icons.help_outline,
                        organizationName:
                            app['organizationName'] ?? 'Unknown Organization',
                        fullApplication:
                            app, // Pass the complete application data
                      ),
                    ),
                    ...pendingApplications.map(
                      (app) => ApplicationProgressCard(
                        id: app['id'] ?? '',
                        category: app['category'] ?? 'Unknown',
                        programName: app['programName'] ?? 'Unknown Program',
                        deadline: app['deadline'] ?? 'No Deadline',
                        status: app['status'] ?? 'Unknown',
                        categoryColor: app['categoryColor'] ?? Colors.grey,
                        organizationLogo:
                            app['organizationLogo'] ?? Icons.help_outline,
                        organizationName:
                            app['organizationName'] ?? 'Unknown Organization',
                        fullApplication:
                            app, // Pass the complete application data
                      ),
                    ),
                    ...completedApplications.map(
                      (app) => ApplicationProgressCard(
                        id: app['id'] ?? '',
                        category: app['category'] ?? 'Unknown',
                        programName: app['programName'] ?? 'Unknown Program',
                        deadline: app['deadline'] ?? 'No Deadline',
                        status: app['status'] ?? 'Unknown',
                        categoryColor: app['categoryColor'] ?? Colors.grey,
                        organizationLogo:
                            app['organizationLogo'] ?? Icons.help_outline,
                        organizationName:
                            app['organizationName'] ?? 'Unknown Organization',
                        fullApplication:
                            app, // Pass the complete application data
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
