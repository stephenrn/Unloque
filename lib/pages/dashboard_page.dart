import 'package:flutter/material.dart';
import '../components/auto_image_slider.dart';
import '../models/slider_item.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<SliderItem> sliderItems = [
      SliderItem(
        categoryLabel: 'Education',
        icon: Icons.book,
        date: '2023-10-01',
        headline: 'EduPH Opportunity 2.0',
        backgroundImage:
            'https://plus.unsplash.com/premium_photo-1664474619075-644dd191935f?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8aW1hZ2V8ZW58MHx8MHx8fDA%3D',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unloque',
                  style: TextStyle(
                      fontSize: 40,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold)),
              Text('Mabuhay!',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic)),
            ],
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
