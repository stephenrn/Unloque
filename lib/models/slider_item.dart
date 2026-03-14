
class SliderItem {
  final String categoryLabel;
  final String source;
  final String date;
  final String headline;
  final String backgroundImage;
  final bool isUrgent;

  SliderItem({
    required this.categoryLabel,
    required this.source,
    required this.date,
    required this.headline,
    required this.backgroundImage,
    this.isUrgent = false,
  });
}
