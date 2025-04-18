import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unloque/components/application_progress_section.dart';
import 'package:unloque/components/categories_section.dart';
import 'package:unloque/pages/admin/developer_options_page.dart';
import 'package:unloque/pages/notification_page.dart';
import '../components/news-slider.dart';
import '../models/slider_item.dart';
import '../data/available_applications_data.dart';
import '../pages/program_search_results_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ApplicationProgressSectionState> _progressSectionKey =
      GlobalKey();
  final GlobalKey<AutoImageSliderState> _newsSliderKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _categoriesSectionKey = GlobalKey();
  // Add a controller for search
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear cache when dashboard loads to ensure fresh data
    AvailableApplicationsData.clearCache();
  }

  @override
  void dispose() {
    // Dispose the search controller
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void refreshProgressSection() {
    _progressSectionKey.currentState?.refreshApplications();
  }

  // Method to refresh the entire dashboard
  void refreshDashboard() {
    setState(() {
      // Clear data cache to force fresh data
      AvailableApplicationsData.clearCache();
      // Refresh the progress section
      refreshProgressSection();
      // Directly call the refresh method on the news slider
      _newsSliderKey.currentState?.refreshNews();
      print('Dashboard refreshed from DeveloperOptionsPage');
    });
  }

  // Add a method to handle search
  void _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Show a loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 10),
            Text('Searching programs...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Search for programs
      final results = await AvailableApplicationsData.searchPrograms(query);

      if (!mounted) return;

      // Navigate to search results page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgramSearchResultsPage(
            searchQuery: query,
            searchResults: results,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching programs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Navigate to a page and refresh when returning with a refresh flag
  Future<void> navigateAndRefresh(BuildContext context, Widget page) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    // Refresh if the result is true
    if (result == true) {
      refreshProgressSection();
    }
  }

  // Update the scroll method to scroll to the bottom instead of calculating positions
  void scrollToCategories() {
    // Simply scroll to the bottom of the page
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          scrolledUnderElevation: 0.0,
          toolbarHeight: 80,
          backgroundColor: Colors.grey[850] ?? Colors.grey,
          elevation: 0,
          title: Column(
            children: [
              SizedBox(height: 30),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  // Get username and photo if available
                  String username = '';
                  String? photoUrl;

                  if (snapshot.connectionState != ConnectionState.waiting &&
                      !snapshot.hasError &&
                      snapshot.hasData &&
                      snapshot.data!.exists) {
                    // Extract username if available
                    var userData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    if (userData.containsKey('username')) {
                      username = userData['username'] ?? '';
                    }
                    if (userData.containsKey('photoUrl')) {
                      photoUrl = userData['photoUrl'];
                    }
                  }

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[400] ?? Colors.grey,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome Back',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic)),
                            Row(
                              children: [
                                Text('Mabuhay, ',
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500)),
                                Flexible(
                                  child: Text(
                                    username.isNotEmpty ? '$username!' : '!',
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.blue[200] ?? Colors.blue,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Developer/Admin button
                      IconButton(
                        icon: Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 26),
                        onPressed: () async {
                          // Navigate to DeveloperOptionsPage and await result
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeveloperOptionsPage(),
                            ),
                          );

                          // If result is true, refresh the dashboard
                          if (result == true) {
                            refreshDashboard();
                          }
                        },
                        tooltip: 'Developer Options',
                      ),
                      // Notification button with badge for unread notifications
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.uid)
                            .collection('notifications')
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          int unreadCount = 0;
                          if (snapshot.hasData && !snapshot.hasError) {
                            unreadCount = snapshot.data!.docs.length;
                          }

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: Icon(Icons.notifications_none_outlined,
                                    size: 30, color: Colors.white),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NotificationPage(),
                                    ),
                                  );
                                },
                                tooltip: 'Notifications',
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 8,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: unreadCount > 9 ? 20 : 16,
                                      minHeight: 16,
                                    ),
                                    child: unreadCount > 9
                                        ? Center(
                                            child: Text(
                                              '9+',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        : unreadCount > 0
                                            ? Center(
                                                child: Text(
                                                  '$unreadCount',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              )
                                            : SizedBox(),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      SizedBox(width: 5),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey[100] ?? Colors.white,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              // Call the method to refresh applications
              refreshProgressSection();

              // Directly refresh the news slider using the GlobalKey
              _newsSliderKey.currentState?.refreshNews();

              // Also clear the applications cache
              AvailableApplicationsData.clearCache();
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  Container(
                    color: Colors.grey[850] ?? Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200] ?? Colors.grey,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style:
                            TextStyle(color: Colors.grey[800] ?? Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Search for programs...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500] ?? Colors.grey,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                          prefixIcon: Icon(Icons.search_outlined,
                              color: Colors.grey[800] ?? Colors.black,
                              size: 22),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.arrow_forward,
                              color: Colors.grey[800] ?? Colors.black,
                              size: 22,
                            ),
                            onPressed: _handleSearch,
                            tooltip: 'Search',
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                        ),
                        onSubmitted: (_) => _handleSearch(),
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: 16),
                    height: 260,
                    clipBehavior: Clip.none,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    child: ApplicationProgressSection(
                      key: _progressSectionKey,
                      scrollToCategories: scrollToCategories,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: AutoImageSlider(key: _newsSliderKey),
                  ),
                  // Add a key to the CategoriesSection for scrolling
                  CategoriesSection(
                    key: _categoriesSectionKey,
                    onNavigate: navigateAndRefresh,
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 40),
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
