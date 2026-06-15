import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/providers/google_auth_provider.dart';
import 'package:life_line_rescuer/providers/rescuer_onboarding_provider.dart';
import 'package:life_line_rescuer/services/auth_service.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/widgets/global/page_message.dart';

class GoogleAuthentication extends StatelessWidget {
  final WidgetRef ref;
  const GoogleAuthentication(this.ref, {super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.mounted) return const SizedBox.shrink();
    final isLoading = ref.watch(googleAuthProvider);
    return ElevatedButton(
      onPressed: isLoading ? null : () => _handleGoogleSignIn(context, ref),
      style: AppButtons.dialogAgree,
      child:
          isLoading
              ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primaryMaroon,
                ),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/google_logo.webp', height: 24),
                  const SizedBox(width: 12),
                  const Text('Continue with Google'),
                ],
              ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    if (context.mounted) {
      ref.read(googleAuthProvider.notifier).state = true;
    }

    try {
      final userCredential = await GoogleSignInService.signInWithGoogle();

      if (userCredential != null && context.mounted) {
        ref
            .read(rescueOnboardingProvider.notifier)
            .setGoogleAuthenticated(true);
        ref.read(googleAuthProvider.notifier).state = false;
      }
    } catch (e) {
      if (context.mounted) {
        ref.read(googleAuthProvider.notifier).state = false;
        pageMessage('Request not completed $e', context, AppColors.error);
      }
    }
  }
}
