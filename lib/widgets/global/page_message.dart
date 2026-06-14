import 'package:flutter/material.dart';
import 'package:life_line_rescuer/styles/styles.dart';

void pageMessage(String message, BuildContext context, Color color) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: AppText.small.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
