import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unloque/components/application_progress_section.dart';
import 'package:unloque/components/categories_section.dart';
import '../components/auto_image_slider.dart';
import '../models/slider_item.dart'; // Add this import

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ApplicationProgressSectionState> _progressSectionKey =
      GlobalKey();

  void refreshProgressSection() {
    _progressSectionKey.currentState?.refreshApplications();
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    List<SliderItem> sliderItems = [
      SliderItem(
        categoryLabel: 'Education',
        source: 'Department of Education',
        date: 'Feb 10, 2024',
        headline: 'EduPH Opportunity 2.0 Program Launches Nationwide',
        backgroundImage:
            'https://www.borgenmagazine.com/wp-content/uploads/2024/08/8644294742_96b35cd70a_k.jpg',
        route: '/sampleartceducation',
      ),
      SliderItem(
        categoryLabel: 'Scholarship',
        source: 'DOST-SEI',
        date: 'Feb 15, 2024',
        headline:
            'Applications Open for 2025 DOST-SEI Undergraduate Scholarships',
        backgroundImage:
            'https://sa.kapamilya.com/absnews/abscbnnews/media/2022/news/09/12/20220824-florita-cagayan-valley-medical-jc-3516.jpg',
        route: '/sampleartchealthcare',
      ),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          scrolledUnderElevation: 0.0, // Add this line
          toolbarHeight: 80,
          backgroundColor: Colors.grey[850],
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Loading...',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic));
                  }
                  if (snapshot.hasError) {
                    return Text('Error',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Text('No Data',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic));
                  }
                  String username = snapshot.data!['username'];
                  String? photoUrl = snapshot.data!['photoUrl'];
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[400],
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: 15),
                      Column(
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
                              Text('$username!',
                                  style: TextStyle(
                                      fontSize: 22,
                                      color: Colors.blue[200],
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                      Spacer(),
                      Icon(Icons.notifications_none_outlined,
                          size: 30, color: Colors.white),
                      SizedBox(width: 5),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  color: Colors.grey[850],
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      style: TextStyle(color: Colors.grey[800]),
                      decoration: InputDecoration(
                        hintText: 'Search for programs...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                        prefixIcon: Icon(Icons.search_outlined,
                            color: Colors.grey[800], size: 22),
                        suffixIcon: Icon(Icons.tune_outlined,
                            color: Colors.grey[800], size: 22),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(bottom: 40),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: ApplicationProgressSection(key: _progressSectionKey),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: AutoImageSlider(
                    items: sliderItems,
                  ),
                ),
                CategoriesSection(),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
