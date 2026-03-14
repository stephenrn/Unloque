class NewsCardItem {
  final String categoryLabel;
  final String source;
  final String date;
  final String headline;
  final String backgroundImage;
  final bool isUrgent;

  const NewsCardItem({
    required this.categoryLabel,
    required this.source,
    required this.date,
    required this.headline,
    required this.backgroundImage,
    this.isUrgent = false,
  });

  factory NewsCardItem.fromMap(Map<String, dynamic> map) {
    return NewsCardItem(
      categoryLabel: (map['categoryLabel'] ?? map['category'] ?? '').toString(),
      source: (map['source'] ?? '').toString(),
      date: (map['date'] ?? '').toString(),
      headline: (map['headline'] ?? '').toString(),
      backgroundImage: (map['backgroundImage'] ?? map['image'] ?? '').toString(),
      isUrgent: map['isUrgent'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'categoryLabel': categoryLabel,
      'source': source,
      'date': date,
      'headline': headline,
      'backgroundImage': backgroundImage,
      'isUrgent': isUrgent,
    };
  }

  NewsCardItem copyWith({
    String? categoryLabel,
    String? source,
    String? date,
    String? headline,
    String? backgroundImage,
    bool? isUrgent,
  }) {
    return NewsCardItem(
      categoryLabel: categoryLabel ?? this.categoryLabel,
      source: source ?? this.source,
      date: date ?? this.date,
      headline: headline ?? this.headline,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }

  static List<NewsCardItem> listFromDynamic(dynamic value) {
    if (value is! List) return <NewsCardItem>[];

    return value
        .whereType<Map>()
        .map((m) => NewsCardItem.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  bool operator ==(Object other) {
    return other is NewsCardItem &&
        other.categoryLabel == categoryLabel &&
        other.source == source &&
        other.date == date &&
        other.headline == headline &&
        other.backgroundImage == backgroundImage &&
        other.isUrgent == isUrgent;
  }

  @override
  int get hashCode => Object.hash(
        categoryLabel,
        source,
        date,
        headline,
        backgroundImage,
        isUrgent,
      );
}
