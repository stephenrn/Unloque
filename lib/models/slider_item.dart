import 'package:flutter/material.dart';

class SliderItem {
  final String categoryLabel;
  final String source;
  final String date;
  final String headline;
  final String backgroundImage;
  final String route;
  final bool isUrgent;

  SliderItem({
    required this.categoryLabel,
    required this.source,
    required this.date,
    required this.headline,
    required this.backgroundImage,
    required this.route,
    this.isUrgent = false,
  });
}
