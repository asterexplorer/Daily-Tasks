import 'package:flutter/material.dart';

class MoodTheme {
  static const String defaultMood = 'default';

  static final Map<String, LinearGradient> gradients = {
    'default': const LinearGradient(
      colors: [Colors.white, Colors.white],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'creative': const LinearGradient(
      colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'focus': const LinearGradient(
      colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'chill': const LinearGradient(
      colors: [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'energy': const LinearGradient(
      colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };

  static Color getTextColor(String mood) {
    if (mood == 'default') return Colors.black87;
    return Colors
        .white; // Most gradients are vibrant/dark enough or look good with white text + shadow
    // Actually, for lighter pastels (creative/chill), dark text might be better.
    // Let's stick to a safe dark gray for pastel-ish ones if we want to be safe,
    // or keep it simple with text shadows.
    // Given the gradient choices:
    // creative (light purple/blue) -> Dark Text preferred
    // focus (purple/pink) -> Dark or White (borderline)
    // chill (green/blue) -> Dark Text preferred
    // energy (orange/yellow) -> Dark Text preferred

    // Changing standard to Dark Grey for better readability on these pastels.
  }

  static IconData getIcon(String mood) {
    switch (mood) {
      case 'creative':
        return Icons.brush_rounded;
      case 'focus':
        return Icons.timer_rounded;
      case 'chill':
        return Icons.spa_rounded;
      case 'energy':
        return Icons.bolt_rounded;
      default:
        return Icons.format_list_bulleted_rounded;
    }
  }
}
