import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/auto_image_slider.dart';
import '../models/slider_item.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    List<SliderItem> sliderItems = [
      SliderItem(
        categoryLabel: 'Education',
        icon: Icons.book,
        date: '2023-10-01',
        headline: 'EduPH Opportunity 2.0',
        backgroundImage:
            'https://www.borgenmagazine.com/wp-content/uploads/2024/08/8644294742_96b35cd70a_k.jpg',
        route: '/sampleartceducation',
      ),
      SliderItem(
        categoryLabel: 'Healthcare',
        icon: Icons.health_and_safety,
        date: '2023-10-02',
        headline: 'New Health Trends',
        backgroundImage:
            'https://sa.kapamilya.com/absnews/abscbnnews/media/2022/news/09/12/20220824-florita-cagayan-valley-medical-jc-3516.jpg',
        route: '/sampleartchealthcare',
      ),
      // Add more items as needed
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Colors.grey[200],
        title: Padding(
          padding: const EdgeInsets.all(10.0),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unloque',
                      style: TextStyle(
                          fontSize: 40,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold)),
                  Text('Mabuhay $username!',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic)),
                ],
              );
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.black,
            height: 1.0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Icon(Icons.notifications_none_outlined, size: 30),
          ),
        ],
      ),
      backgroundColor: Colors.grey[300],
      body: Column(
        children: [
          const SizedBox(height: 50),
          AutoImageSlider(
            items: sliderItems,
          ),
          // Other widgets can be added here
          Expanded(
            child: Center(
              child: Text("Home Page"),
            ),
          ),
        ],
      ),
    );
  }
}
