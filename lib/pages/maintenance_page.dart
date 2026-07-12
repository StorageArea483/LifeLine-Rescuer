import 'package:flutter/material.dart';
import 'package:life_line_rescuer/styles/styles.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryMaroon.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.construction,
                      size: 50,
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'System Under Maintenance',
                  style: AppText.formTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We are currently performing system maintenance to improve your experience. Please check back shortly.',
                  style: AppText.small.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
