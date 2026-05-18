import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles({
    this.title = const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    this.subtitle = const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    this.body = const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    this.caption = const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  });

  final TextStyle title;
  final TextStyle subtitle;
  final TextStyle body;
  final TextStyle caption;

  static const AppTextStyles defaults = AppTextStyles();
}
