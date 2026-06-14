import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'package:life_line_rescuer/pages/rescuer_onboarding.dart';
import 'package:life_line_rescuer/providers/auth_provider.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/widgets/internet_connection.dart';

class CheckConnection extends ConsumerWidget {
  const CheckConnection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!context.mounted) return const SizedBox.shrink();
    final authSync = ref.watch(authStateProvider);
    return authSync.when(
      data: (user) {
        if (user == null) {
          return const InternetConnection(child: RescuerOnboarding());
        }
        return const InternetConnection(child: LandingPage());
      },
      error: (error, stack) {
        return const InternetConnection(child: RescuerOnboarding());
      },
      loading: () {
        return _loadingScreen();
      },
    );
  }

  Widget _loadingScreen() {
    return Scaffold(
      body: Container(
        decoration: AppContainers.pageContainer,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryMaroon),
        ),
      ),
    );
  }
}
