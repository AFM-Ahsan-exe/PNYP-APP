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

  // Status chips
  static const Color statusApprovedBg = Color(0xFFE6F7EF);
  static const Color statusApprovedFg = Color(0xFF15803D);
  static const Color statusPendingBg = Color(0xFFFFFBEB);
  static const Color statusPendingFg = Color(0xFFB45309);
  static const Color statusRejectedBg = Color(0xFFFEF2F2);
  static const Color statusRejectedFg = Color(0xFFB91C1C);
  static const Color statusSuspendedBg = Color(0xFFFEF2F2);
  static const Color statusSuspendedFg = Color(0xFFB91C1C);
  static const Color statusExpiredBg = Color(0xFFFEF2F2);
  static const Color statusExpiredFg = Color(0xFFB91C1C);
  static const Color statusActiveBg = Color(0xFFE6F7EF);
  static const Color statusActiveFg = Color(0xFF15803D);
  static const Color statusInactiveBg = Color(0xFFF3F4F6);
  static const Color statusInactiveFg = Color(0xFF6B7280);
  static const Color statusDraftBg = Color(0xFFF3F4F6);
  static const Color statusDraftFg = Color(0xFF6B7280);
  static const Color statusCancelledBg = Color(0xFFFEF2F2);
  static const Color statusCancelledFg = Color(0xFFB91C1C);
  static const Color statusCompletedBg = Color(0xFFE6F7EF);
  static const Color statusCompletedFg = Color(0xFF15803D);
  static const Color statusOngoingBg = Color(0xFFEFF6FF);
  static const Color statusOngoingFg = Color(0xFF1D4ED8);
  static const Color statusUpcomingBg = Color(0xFFEFF6FF);
  static const Color statusUpcomingFg = Color(0xFF1D4ED8);
}
