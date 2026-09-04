import 'package:flutter/material.dart';

import '../../app/theme/app_text_styles.dart';

class AppListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final Widget? leading;

  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = subtitle == null ? title : '$title, $subtitle';
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: dense ? 10 : 14,
            ),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: dense
                            ? AppTextStyles.listTitle.copyWith(fontSize: 14)
                            : AppTextStyles.listTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: dense
                              ? AppTextStyles.listSubtitle.copyWith(
                                  fontSize: 12,
                                )
                              : AppTextStyles.listSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
