import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool compact;

  const StatusChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.statusInactiveBg;
    final fg = foregroundColor ?? AppColors.statusInactiveFg;
    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: compact
              ? AppTextStyles.caption.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                )
              : AppTextStyles.body.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
        ),
      ),
    );
  }
}

Color statusColorFor(String status) {
  final key = status.toLowerCase();
  if (key == 'approved' ||
      key == 'active' ||
      key == 'completed' ||
      key == 'accepted') {
    return AppColors.statusApprovedFg;
  }
  if (key == 'pending') {
    return AppColors.statusPendingFg;
  }
  if (key == 'rejected' ||
      key == 'suspended' ||
      key == 'expired' ||
      key == 'cancelled') {
    return AppColors.statusRejectedFg;
  }
  if (key == 'ongoing' || key == 'upcoming') {
    return AppColors.statusUpcomingFg;
  }
  if (key == 'draft' || key == 'paused' || key == 'inactive') {
    return AppColors.statusInactiveFg;
  }
  return AppColors.textSecondary;
}

Color statusBgFor(String status) {
  final key = status.toLowerCase();
  if (key == 'approved' ||
      key == 'active' ||
      key == 'completed' ||
      key == 'accepted') {
    return AppColors.statusApprovedBg;
  }
  if (key == 'pending') {
    return AppColors.statusPendingBg;
  }
  if (key == 'rejected' ||
      key == 'suspended' ||
      key == 'expired' ||
      key == 'cancelled') {
    return AppColors.statusRejectedBg;
  }
  if (key == 'ongoing' || key == 'upcoming') {
    return AppColors.statusUpcomingBg;
  }
  if (key == 'draft' || key == 'paused' || key == 'inactive') {
    return AppColors.statusInactiveBg;
  }
  return AppColors.surfaceMuted;
}
