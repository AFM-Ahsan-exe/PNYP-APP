import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../../app/theme/app_text_styles.dart';

class DashboardLoadingView extends StatelessWidget {
  final double height;

  const DashboardLoadingView({super.key, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
    );
  }
}

class DashboardErrorView extends StatelessWidget {
  final String message;

  final VoidCallback? onRetry;

  const DashboardErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(height: 10),
          Text(
            'Couldn\'t load this data',
            style: AppTextStyles.title.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 4),
          Text(message, style: AppTextStyles.bodyMuted),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardEmptyView extends StatelessWidget {
  final String message;

  final IconData icon;

  const DashboardEmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}