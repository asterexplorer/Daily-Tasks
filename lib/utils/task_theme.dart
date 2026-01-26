import 'package:flutter/material.dart';

class TaskTheme {
  static final Map<String, Color> priorityColors = {
    'Low': const Color(0xFF4CAF50),
    'Medium': const Color(0xFFFFC107),
    'High': const Color(0xFFF44336),
  };

  static final Map<String, IconData> categoryIcons = {
    'Personal': Icons.person_rounded,
    'Work': Icons.work_rounded,
    'Health': Icons.favorite_rounded,
    'Study': Icons.menu_book_rounded,
    'Other': Icons.more_horiz_rounded,
  };

  static final Map<String, Color> categoryColors = {
    'Personal': const Color(0xFF2196F3),
    'Work': const Color(0xFF9C27B0),
    'Health': const Color(0xFFE91E63),
    'Study': const Color(0xFFFF9800),
    'Other': const Color(0xFF607D8B),
  };

  static List<String> get priorities => ['Low', 'Medium', 'High'];
  static List<String> get categories => ['Personal', 'Work', 'Health', 'Study', 'Other'];
}
