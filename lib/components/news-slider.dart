import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../models/slider_item.dart';
import '../constants/category_colors.dart';
import '../utils/web_viewer.dart';
import '../pages/all_news_page.dart'; // Add this import
import 'dart:async';

class AutoImageSlider extends StatefulWidget {
  const AutoImageSlider({super.key});

  @override
  State<AutoImageSlider> createState() => AutoImageSliderState();
}

class AutoImageSliderState extends State<AutoImageSlider> {
  List<_NewsSliderItem> _newsItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  // Public method that can be called directly via GlobalKey
  void refreshNews() {
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
      final orgLogoUrl =
          orgDoc.data()['logoUrl'] ?? ''; // Fetch the organization logo URL
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
          logoUrl: orgLogoUrl, // Pass the organization logo URL
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
    return Column(
      children: [
        // Always show the header and view all button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'News Articles',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[800],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Navigate to All News page instead of refreshing
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllNewsPage()),
                  );
                },
                icon: Icon(
                  Icons.article_outlined,
                  color: Colors.grey[800],
                  size: 14,
                ),
                label: Text(
                  'All',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: Size(0, 25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Conditionally show loading indicator, empty state message, or carousel
        if (_loading)
          Container(
            height: 200, // Match the approximate height of the carousel
            width: double.infinity, // Ensure full width
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Loading news...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_newsItems.isEmpty)
          Container(
            height: 200, // Match the approximate height of the carousel
            child: Center(
              child: Text(
                'No news available.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
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
  final String logoUrl; // Add this field for organization logo

  _NewsSliderItem({
    required this.headline,
    required this.category,
    required this.date,
    required this.imageUrl,
    required this.newsUrl,
    required this.organizationName,
    this.logoUrl = '', // Default to empty string
  });
}

class _NewsCard extends StatelessWidget {
  final _NewsSliderItem item;

  const _NewsCard({super.key, required this.item});

  // Updated colors to even lighter variants
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'healthcare':
        return Colors.red[300]!; // Even lighter red
      case 'education':
        return Colors.blue[300]!; // Even lighter blue
      case 'social':
        return Colors.green[300]!; // Even lighter green
      default:
        return Colors.grey[300]!; // Even lighter grey
    }
  }

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
              // Background Image with error handling
              item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Handle image loading errors gracefully
                        print('Error loading image: $error');
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 40, color: Colors.grey[600]),
                                SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
                    // Category Badge - updated to use custom color function
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(item.category),
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
                    // Source and Date - Fix for long organization names
                    Row(
                      children: [
                        Container(
                          width: 24, // Bigger container
                          height: 24, // Bigger container
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                5), // Rounded box instead of circle
                          ),
                          child: item.logoUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      5), // Match container's border radius
                                  child: Image.network(
                                    item.logoUrl,
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.business,
                                          size: 12, color: Colors.grey[600]);
                                    },
                                  ),
                                )
                              : Icon(Icons.business,
                                  size: 16, color: Colors.grey[600]),
                        ),
                        SizedBox(width: 4),
                        // Wrap organization name in Expanded with ellipsis
                        Expanded(
                          child: Text(
                            item.organizationName,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 12),
                        // Ensure date always shows by not allowing it to be squeezed out
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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

  // Updated colors to even lighter variants
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'healthcare':
        return Colors.red[300]!; // Even lighter red
      case 'education':
        return Colors.blue[300]!; // Even lighter blue
      case 'social':
        return Colors.green[300]!; // Even lighter green
      default:
        return Colors.grey[300]!; // Even lighter grey
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use actual logo if available with updated styling
    Widget orgIcon = Container(
      width: 24, // Bigger container
      height: 24, // Bigger container
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5), // Rounded box instead of circle
      ),
      child: item.logoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius:
                  BorderRadius.circular(5), // Match container's border radius
              child: Image.network(
                item.logoUrl,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.business,
                      size: 16, color: Colors.grey[600]);
                },
              ),
            )
          : Icon(Icons.business, size: 16, color: Colors.grey[600]),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with image - Add error handling
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image in dialog: $error');
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Unable to load image',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
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
                // Category badge with custom color
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(item.category),
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
                // Organization and date with organization logo - Fix layout for long organization names
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    orgIcon,
                    SizedBox(width: 4),
                    // Wrap the organization name in an Expanded to handle long text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.organizationName.isNotEmpty
                                ? item.organizationName
                                : 'Organization',
                            style: TextStyle(color: Colors.grey[700]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          // Move date below for cleaner layout when org name is long
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: Colors.grey[700]),
                              SizedBox(width: 4),
                              Text(
                                item.date,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 24),
                // Grey button without org icon
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.open_in_browser),
                    label: Text("View Full Article"),
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
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[800],
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
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
