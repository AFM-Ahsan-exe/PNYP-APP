import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Error: $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Could not load data',
                style: AppTextStyles.title.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodyMuted,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
