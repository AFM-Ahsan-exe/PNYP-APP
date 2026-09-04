import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class AppPageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final double height;

  const AppPageHeader({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.height = 56,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: title,
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            if (actions == null || actions!.isEmpty)
              const SizedBox(width: 40)
            else if (actions!.length == 1 && actions!.first is IconButton)
              actions!.first
            else ...[
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headline,
                  textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: actions!),
              const SizedBox(width: 8),
            ],
            if (actions == null || actions!.isEmpty)
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headline,
                  textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
