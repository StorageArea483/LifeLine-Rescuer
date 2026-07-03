import 'package:flutter/material.dart';
import 'package:life_line_rescuer/styles/styles.dart';

class OfflineConnectivity extends StatelessWidget {
  const OfflineConnectivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppContainers.pageContainer,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMaroon.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off,
                      size: 80,
                      color: AppColors.primaryMaroon,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'No Internet Connection',
                    style: AppText.welcomeTitle.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Please check your internet connection and try again.',
                    style: AppText.formDescription.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  const CircularProgressIndicator(
                    color: AppColors.primaryMaroon,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Waiting for connection...',
                    style: AppText.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
