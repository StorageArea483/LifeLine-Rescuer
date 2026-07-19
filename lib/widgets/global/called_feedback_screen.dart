import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'package:life_line_rescuer/providers/call_state_provider.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/widgets/global/in_out_calls.dart';
import 'package:life_line_rescuer/widgets/global/page_navigation.dart';

class CallFeedbackScreen extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const CallFeedbackScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
              ),
              onPressed: () {
                ref.read(currentCallIdProvider.notifier).state = null;
                pageNavigation(const InOutCalls(child: LandingPage()), context);
              },
              child: const Text(
                "Go Home",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
