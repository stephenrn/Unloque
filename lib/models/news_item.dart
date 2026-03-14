class NewsItem {
  final String id;
  final String headline;
  final String category;
  final String date;
  final String imageUrl;
  final String newsUrl;
  final String organizationName;
  final String organizationId;
  final String logoUrl;

  const NewsItem({
    required this.id,
    required this.headline,
    required this.category,
    required this.date,
    required this.imageUrl,
    required this.newsUrl,
    required this.organizationName,
    required this.organizationId,
    required this.logoUrl,
  });

  factory NewsItem.fromMap(Map<String, dynamic> map) {
    return NewsItem(
      id: (map['id'] ?? '').toString(),
      headline: (map['headline'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      date: (map['date'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      newsUrl: (map['newsUrl'] ?? '').toString(),
      organizationName: (map['organizationName'] ?? '').toString(),
      organizationId: (map['organizationId'] ?? '').toString(),
      logoUrl: (map['logoUrl'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'headline': headline,
      'category': category,
      'date': date,
      'imageUrl': imageUrl,
      'newsUrl': newsUrl,
      'organizationName': organizationName,
      'organizationId': organizationId,
      'logoUrl': logoUrl,
    };
  }
}
