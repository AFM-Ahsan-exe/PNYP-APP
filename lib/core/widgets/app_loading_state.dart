import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppLoadingState extends StatelessWidget {
  final String? message;

  const AppLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message ?? 'Loading',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.navyDeep,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
