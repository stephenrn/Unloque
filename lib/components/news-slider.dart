import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../models/slider_item.dart';
import '../constants/category_colors.dart';
import '../utils/web_viewer.dart';
import 'dart:async';

class AutoImageSlider extends StatefulWidget {
  const AutoImageSlider({super.key});

  @override
  State<AutoImageSlider> createState() => _AutoImageSliderState();
}

class _AutoImageSliderState extends State<AutoImageSlider> {
  List<_NewsSliderItem> _newsItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _loading = true;
    });

    final List<_NewsSliderItem> items = [];
    final orgs =
        await FirebaseFirestore.instance.collection('organizations').get();

    for (final orgDoc in orgs.docs) {
      final orgName = orgDoc.data()['name'] ?? 'Organization';
      final newsSnap = await orgDoc.reference
          .collection('news')
          .orderBy('date', descending: true)
          .get();
      for (final newsDoc in newsSnap.docs) {
        final news = newsDoc.data();
        items.add(_NewsSliderItem(
          headline: news['headline'] ?? '',
          category: news['category'] ?? '',
          date: news['date'] ?? '',
          imageUrl: news['imageUrl'] ?? '',
          newsUrl: news['newsUrl'] ?? '',
          organizationName: orgName,
        ));
      }
    }

    setState(() {
      _newsItems = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_newsItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
            child: Text('No news available.',
                style: TextStyle(color: Colors.grey[600]))),
      );
    }
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
                onPressed: _fetchNews,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: Size(0, 25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Refresh',
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
            viewportFraction: 0.80,
            enlargeCenterPage: true,
            enlargeFactor: 0.25,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 5),
          ),
          items: _newsItems.map((item) => _NewsCard(item: item)).toList(),
        ),
      ],
    );
  }
}

class _NewsSliderItem {
  final String headline;
  final String category;
  final String date;
  final String imageUrl;
  final String newsUrl;
  final String organizationName;

  _NewsSliderItem({
    required this.headline,
    required this.category,
    required this.date,
    required this.imageUrl,
    required this.newsUrl,
    required this.organizationName,
  });
}

class _NewsCard extends StatelessWidget {
  final _NewsSliderItem item;

  const _NewsCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (item.newsUrl.isNotEmpty) {
          // Show a more detailed news viewer dialog
          showDialog(
            context: context,
            builder: (context) => NewsViewerDialog(item: item),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No news content available.')),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
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
              item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(color: Colors.grey[300]),
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
                        color:
                            CategoryColors.colors[item.category] ?? Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
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
                        Icon(Icons.business, color: Colors.white70, size: 14),
                        SizedBox(width: 4),
                        Text(
                          item.organizationName,
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

class NewsViewerDialog extends StatelessWidget {
  final _NewsSliderItem item;

  const NewsViewerDialog({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with image
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported,
                        size: 50, color: Colors.grey),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CategoryColors.colors[item.category] ?? Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.category.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // News headline
                Text(
                  item.headline,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                // Organization and date
                Row(
                  children: [
                    Icon(Icons.business, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 4),
                    Text(
                      item.organizationName,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey[700]),
                    SizedBox(width: 4),
                    Text(
                      item.date,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                Divider(height: 24),
                // Replace the URL notice section with viewing options
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "How would you like to view this content?",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.open_in_browser, size: 16),
                            label: Text("Open in app"),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SafeWebViewer(
                                    url: item.newsUrl,
                                    title: 'News',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.launch, size: 16),
                            label: Text("External browser"),
                            onPressed: () async {
                              try {
                                final uri = Uri.parse(item.newsUrl);
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Could not open link: $e')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, right: 16),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('CLOSE'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
