import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unloque/models/news_item.dart';

class NewsService {
  static Future<List<NewsItem>> fetchAllNews() async {
    final List<NewsItem> allNewsItems = [];

    final orgsSnapshot =
        await FirebaseFirestore.instance.collection('organizations').get();

    for (final orgDoc in orgsSnapshot.docs) {
      final orgId = orgDoc.id;
      final orgData = orgDoc.data();
      final orgName = orgData['name'] ?? 'Organization';
      final logoUrl = orgData['logoUrl'] ?? '';

      final newsSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .collection('news')
          .orderBy('date', descending: true)
          .get();

      for (final newsDoc in newsSnapshot.docs) {
        final newsData = newsDoc.data();
        allNewsItems.add(
          NewsItem(
            id: newsDoc.id,
            headline: (newsData['headline'] ?? '').toString(),
            category: (newsData['category'] ?? '').toString(),
            date: (newsData['date'] ?? '').toString(),
            imageUrl: (newsData['imageUrl'] ?? '').toString(),
            newsUrl: (newsData['newsUrl'] ?? '').toString(),
            organizationName: orgName.toString(),
            organizationId: orgId,
            logoUrl: logoUrl.toString(),
          ),
        );
      }
    }

    allNewsItems.sort((a, b) => b.date.compareTo(a.date));
    return allNewsItems;
  }
}
