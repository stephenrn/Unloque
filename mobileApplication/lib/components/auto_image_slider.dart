import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/slider_item.dart';
import '../constants/category_colors.dart';

class AutoImageSlider extends StatelessWidget {
  // Move the sliderItems list here
  final List<SliderItem> items = [
    SliderItem(
      categoryLabel: 'Education',
      source: 'Department of Education',
      date: 'Feb 10, 2024',
      headline: 'EduPH Opportunity 2.0 Program Launches Nationwide',
      backgroundImage:
          'https://www.borgenmagazine.com/wp-content/uploads/2024/08/8644294742_96b35cd70a_k.jpg',
    ),
    SliderItem(
      categoryLabel: 'Scholarship',
      source: 'DOST-SEI',
      date: 'Feb 15, 2024',
      headline:
          'Applications Open for 2025 DOST-SEI Undergraduate Scholarships',
      backgroundImage:
          'https://sa.kapamilya.com/absnews/abscbnnews/media/2022/news/09/12/20220824-florita-cagayan-valley-medical-jc-3516.jpg',
    ),
  ];

  AutoImageSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Breaking News',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to news feed page
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: Size(0, 25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Show All',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        CarouselSlider(
          options: CarouselOptions(
            aspectRatio: 16 / 9,
            viewportFraction: 0.80, // Increased from 0.85
            enlargeCenterPage: true,
            enlargeFactor: 0.25, // Added to reduce the enlargement effect
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 5),
          ),
          items: items.map((item) => NewsCard(item: item)).toList(),
        ),
      ],
    );
  }
}

class NewsCard extends StatelessWidget {
  final SliderItem item;

  const NewsCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Prevent opening a webview to avoid triggering the channel-error exception.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('News details are not available in this demo.')),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: 2.0, vertical: 8.0), // Reduced from horizontal: 5.0
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.network(
                item.backgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  assert(() {
                    // ignore: only_throw_errors, since we're just proxying the error.
                    throw error; // Ensures the error message is printed to the console.
                  }());
                  // Fallback widget for release mode
                  return Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.grey, size: 48),
                    ),
                  );
                },
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CategoryColors.colors[item.categoryLabel] ??
                            Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.categoryLabel.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    // Source and Date
                    Row(
                      children: [
                        Icon(Icons.source, color: Colors.white70, size: 14),
                        SizedBox(width: 4),
                        Text(
                          item.source,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.calendar_today,
                            color: Colors.white70, size: 14),
                        SizedBox(width: 4),
                        Text(
                          item.date,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Headline
                    Text(
                      item.headline,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
