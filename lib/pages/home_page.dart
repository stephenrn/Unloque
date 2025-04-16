import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'history_page.dart';
import 'map_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // Add a static navigation method that can be called from anywhere
  static void navigateToTab(BuildContext context, int index) {
    final homeState = context.findRootAncestorStateOfType<_HomePageState>();
    if (homeState != null && homeState.mounted) {
      homeState._navigateBottomBar(index);
    }
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    DashboardPage(),
    MapPage(),
    HistoryPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.grey[200],
          currentIndex: _selectedIndex,
          onTap: _navigateBottomBar,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[500],
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding:
                    EdgeInsets.only(top: 10, left: 60), // Indent icon closer
                child: Icon(Icons.dashboard, size: 30), // Make icon bigger
              ),
              label: '', // Remove label
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding:
                    EdgeInsets.only(top: 10, left: 25), // Indent icon closer
                child: Icon(Icons.map, size: 30), // Make icon bigger
              ),
              label: '', // Remove label
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding:
                    EdgeInsets.only(top: 10, right: 25), // Indent icon closer
                child: Icon(Icons.history, size: 30), // Make icon bigger
              ),
              label: '', // Remove label
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding:
                    EdgeInsets.only(top: 10, right: 80), // Indent icon closer
                child: Icon(Icons.person, size: 30), // Make icon bigger
              ),
              label: '', // Remove label
            ),
          ],
        ),
      ),
    );
  }
}
