import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:life_line_rescuer/styles/styles.dart';

class RescuerBlockedDialog extends StatelessWidget {
  final String firstName;
  final String lastName;

  const RescuerBlockedDialog({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: 50,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Access Restricted',
                style: AppText.formTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your account associated with $firstName, $lastName has been restricted from using LifeLine services due to a violation of our terms of service.',
                style: AppText.small.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: AppButtons.submit,
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: const Text('Sign Out', style: AppText.submitButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
