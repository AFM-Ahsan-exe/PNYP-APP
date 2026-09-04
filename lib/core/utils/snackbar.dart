import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

void showAppSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
  bool isSuccess = false,
  SnackBarAction? action,
}) {
  final backgroundColor = isError
      ? AppColors.error
      : isSuccess
      ? AppColors.success
      : AppColors.navyDeep;

  final textColor = isError || isSuccess ? Colors.white : Colors.white;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: textColor)),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      action: action,
    ),
  );
}
