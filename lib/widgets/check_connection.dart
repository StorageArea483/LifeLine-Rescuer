import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'package:life_line_rescuer/pages/rescuer_onboarding.dart';
import 'package:life_line_rescuer/providers/auth_provider.dart';
import 'package:life_line_rescuer/providers/rescuer_access_provider.dart';
import 'package:life_line_rescuer/widgets/rescuer_blocked.dart';

class CheckConnection extends ConsumerStatefulWidget {
  const CheckConnection({super.key});
  @override
  ConsumerState<CheckConnection> createState() => _CheckConnectionState();
}

class _CheckConnectionState extends ConsumerState<CheckConnection>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateOnlineStatus(true);
  }

  @override
  void dispose() {
    _updateOnlineStatus(false);

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  Future<void> _updateOnlineStatus(bool online) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'online': online,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updateOnlineStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.mounted) return const SizedBox.shrink();

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const RescuerOnboarding();
        }
        if (!context.mounted) return const SizedBox.shrink();
        final accessState = ref.watch(rescuerAccessProvider);

        return accessState.when(
          data: (access) {
            if (access.blocked) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final navigator = Navigator.of(context, rootNavigator: true);

                while (navigator.canPop()) {
                  navigator.pop();
                }
              });

              return RescuerBlockedDialog(
                firstName: access.firstName,
                lastName: access.lastName,
              );
            }

            if (access.approved) {
              return const LandingPage();
            }

            return const RescuerOnboarding();
          },
          loading: () => const RescuerOnboarding(),
          error: (_, _) => const RescuerOnboarding(),
        );
      },
      loading: () => const RescuerOnboarding(),
      error: (_, _) => const RescuerOnboarding(),
    );
  }
}
