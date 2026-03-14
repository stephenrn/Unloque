import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/web_viewer.dart';

class AllNewsPage extends StatefulWidget {
  const AllNewsPage({Key? key}) : super(key: key);

  @override
  State<AllNewsPage> createState() => _AllNewsPageState();
}

class _AllNewsPageState extends State<AllNewsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allNews = [];

  @override
  void initState() {
    super.initState();
    _loadAllNews();
  }

  Future<void> _loadAllNews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> allNewsItems = [];

      // Get all organizations
      final orgsSnapshot =
          await FirebaseFirestore.instance.collection('organizations').get();

      // For each organization, get its news
      for (final orgDoc in orgsSnapshot.docs) {
        final orgId = orgDoc.id;
        final orgData = orgDoc.data();
        final orgName = orgData['name'] ?? 'Organization';
        final logoUrl = orgData['logoUrl'] ?? '';

        // Get news for this organization
        final newsSnapshot = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('news')
            .orderBy('date', descending: true)
            .get();

        // Add each news item with organization details
        for (final newsDoc in newsSnapshot.docs) {
          final newsData = newsDoc.data();
          allNewsItems.add({
            'id': newsDoc.id,
            'headline': newsData['headline'] ?? '',
            'category': newsData['category'] ?? '',
            'date': newsData['date'] ?? '',
            'imageUrl': newsData['imageUrl'] ?? '',
            'newsUrl': newsData['newsUrl'] ?? '',
            'organizationName': orgName,
            'organizationId': orgId,
            'logoUrl': logoUrl,
          });
        }
      }

      // Sort all news by date, newest first
      allNewsItems.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        _allNews = allNewsItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading news: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        toolbarHeight: 140,
        automaticallyImplyLeading: false,
        flexibleSpace: Padding(
          padding: EdgeInsets.fromLTRB(16, 40, 16, 0),
          child: Row(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  icon: Transform.rotate(
                    angle: 4.71239,
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.grey[900],
                      size: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'All News Article',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[200],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 28),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading news...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : _allNews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No news articles found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAllNews,
                    child: ListView.builder(
                      padding: EdgeInsets.only(top: 24, bottom: 24),
                      itemCount: _allNews.length,
                      itemBuilder: (context, index) {
                        final news = _allNews[index];
                        return NewsCard(news: news);
                      },
                    ),
                  ),
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsCard({
    Key? key,
    required this.news,
  }) : super(key: key);

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'healthcare':
        return Colors.red[300]!;
      case 'education':
        return Colors.blue[300]!;
      case 'social':
        return Colors.green[300]!;
      default:
        return Colors.grey[300]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (news['newsUrl'] != null && news['newsUrl'].isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SafeWebViewer(
                url: news['newsUrl'],
                title: 'News',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No article link available')),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // News image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: news['imageUrl'] != null && news['imageUrl'].isNotEmpty
                  ? Image.network(
                      news['imageUrl'],
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 160,
                          color: Colors.grey[300],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 40, color: Colors.grey[500]),
                                SizedBox(height: 4),
                                Text(
                                  'Image not available',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 160,
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported,
                          size: 40, color: Colors.grey),
                    ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(news['category']),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      news['category'].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Headline
                  Text(
                    news['headline'],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),

                  // Organization and date
                  Row(
                    children: [
                      // Organization logo
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: news['logoUrl'] != null &&
                                  news['logoUrl'].toString().isNotEmpty
                              ? Image.network(
                                  news['logoUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.business,
                                        size: 16, color: Colors.grey[600]);
                                  },
                                )
                              : Icon(Icons.business,
                                  size: 16, color: Colors.grey[600]),
                        ),
                      ),
                      SizedBox(width: 8),

                      // Organization name (with ellipsis for long names)
                      Expanded(
                        child: Text(
                          news['organizationName'],
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(width: 16),

                      // Date
                      Icon(Icons.calendar_today,
                          color: Colors.grey[600], size: 14),
                      SizedBox(width: 4),
                      Text(
                        news['date'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // View Article button
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Article',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.blue[700],
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
