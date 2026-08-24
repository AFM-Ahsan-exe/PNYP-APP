import 'package:flutter/material.dart';

/// PYNP brand palette.
///
/// The navy/blue values here match the gradient already used in
/// `LoginScreen` (0xFF1A1A2E / 0xFF16213E / 0xFF0F3460) so the rest of the
/// app stays visually consistent instead of introducing a second palette.
class AppColors {
  AppColors._();

  // Brand navy (from existing LoginScreen gradient).
  static const Color navyDarkest = Color(0xFF1A1A2E);
  static const Color navyDark = Color(0xFF16213E);
  static const Color navyDeep = Color(0xFF0F3460);

  // Accent blue for CTAs, active states, links.
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentBlueLight = Color(0xFF60A5FA);

  // Surfaces.
  static const Color surface = Color(0xFFF7F8FC);
  static const Color surfaceCard = Colors.white;
  static const Color surfaceMuted = Color(0xFFEEF1F8);
  static const Color border = Color(0xFFE3E7F1);

  // Text.
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF636B85);
  static const Color textOnDark = Colors.white;
  static const Color textOnDarkMuted = Color(0xFFB8BEDA);

  // Status.
  static const Color success = Color(0xFF22A06B);
  static const Color warning = Color(0xFFE8A93B);
  static const Color error = Color(0xFFE0473F);
  static const Color info = accentBlue;

  // Chart series (kept desaturated/professional, not neon).
  static const List<Color> chartSeries = [
    accentBlue,
    Color(0xFF6D5BD0),
    Color(0xFF22A06B),
    Color(0xFFE8A93B),
    Color(0xFFE0473F),
  ];
}
