import 'package:flutter/material.dart';

/// Stylish brand color system.
/// Warm neutrals + deep olive green accent, inspired by the Stylish
/// visual identity: premium, minimal, human, fashion-focused.
class AppColors {
  AppColors._();

  // Core neutrals
  static const Color cream = Color(0xFFFAF9F6);
  static const Color ivory = Color(0xFFFFFFFF);
  static const Color sand = Color(0xFFE6DFD3);
  static const Color sandLight = Color(0xFFF1ECE2);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color charcoalSoft = Color(0xFF33312D);
  static const Color graphite = Color(0xFF5A574F);
  static const Color mutedGray = Color(0xFF8B887E);
  static const Color divider = Color(0xFFE3DDD0);

  // Brand accent
  static const Color olive = Color(0xFF2E5A44);
  static const Color oliveDark = Color(0xFF1E3E2D);
  static const Color oliveLight = Color(0xFF4C7D62);
  static const Color oliveSurface = Color(0xFFE8EEE9);

  // Semantic
  static const Color success = Color(0xFF2E5A44);
  static const Color warning = Color(0xFFB8763A);
  static const Color error = Color(0xFFB0413E);
  static const Color info = Color(0xFF3D6A8A);

  // Gradients (used sparingly per design guidance)
  static const List<Color> heroOverlay = [
    Color(0x00000000),
    Color(0x99000000),
  ];
}
