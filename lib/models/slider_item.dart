import 'package:flutter/material.dart';

class SliderItem {
  final String categoryLabel;
  final IconData icon;
  final String date;
  final String headline;
  final String backgroundImage;
  final String route;

  SliderItem({
    required this.categoryLabel,
    required this.icon,
    required this.date,
    required this.headline,
    required this.backgroundImage,
    required this.route,
  });
}
