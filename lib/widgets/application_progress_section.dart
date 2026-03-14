import 'package:flutter/material.dart';
import '../widgets/application_progress_card.dart';
import 'package:provider/provider.dart';
import 'package:unloque/providers/user_applications_provider.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserApplicationsProvider>().loadAll();
    });
  }

  // Method to refresh the applications list
  Future<void> refreshApplications() async {
    await context.read<UserApplicationsProvider>().loadAll(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserApplicationsProvider>();
    final applications = provider.applications;

    // Calculate application counts by status
    final ongoingApplications =
      applications.where((app) => app['status'] == 'Ongoing').toList();
    final pendingApplications =
      applications.where((app) => app['status'] == 'Pending').toList();
    final completedApplications =
      applications.where((app) => app['status'] == 'Completed').toList();

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
          if (provider.isLoading)
            Expanded(
              child: Container(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Loading applications...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if ((provider.errorMessage ?? '').isNotEmpty)
            Expanded(
              child: Center(
                child: Text(
                  provider.errorMessage ?? 'Failed to load applications',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          else if (applications.isEmpty)
            // Center the empty state content horizontally
            Expanded(
              child: Container(
                width: double.infinity, // Take full width
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center vertically
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Center children horizontally
                  children: [
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
                  ],
                ),
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
