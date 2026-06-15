import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'package:life_line_rescuer/pages/rescuer_onboarding.dart';
import 'package:life_line_rescuer/providers/auth_provider.dart';
import 'package:life_line_rescuer/widgets/internet_connection.dart';
import 'package:life_line_rescuer/providers/rescuer_access_provider.dart';
import 'package:life_line_rescuer/widgets/rescuer_blocked.dart';

class CheckConnection extends ConsumerWidget {
  const CheckConnection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const InternetConnection(child: RescuerOnboarding());
        }
        if (!context.mounted) return const SizedBox.shrink();
        final accessState = ref.watch(rescuerAccessProvider);

        return accessState.when(
          data: (access) {
            if (access.blocked) {
              return RescuerBlockedDialog(
                firstName: access.firstName,
                lastName: access.lastName,
              );
            }

            if (access.approved) {
              return const InternetConnection(child: LandingPage());
            }

            return const InternetConnection(child: RescuerOnboarding());
          },
          loading: () => const InternetConnection(child: RescuerOnboarding()),
          error: (_, _) {
            return const InternetConnection(child: RescuerOnboarding());
          },
        );
      },
      loading: () => const InternetConnection(child: RescuerOnboarding()),
      error: (_, _) {
        return const InternetConnection(child: RescuerOnboarding());
      },
    );
  }
}
