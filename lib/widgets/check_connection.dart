import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'package:life_line_rescuer/pages/maintenance_page.dart';
import 'package:life_line_rescuer/pages/rescuer_blocked.dart';
import 'package:life_line_rescuer/pages/rescuer_onboarding.dart';
import 'package:life_line_rescuer/providers/app_router_provider.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/widgets/global/in_out_calls.dart';
import 'package:life_line_rescuer/widgets/global/rescuer_online_status.dart';
import 'package:life_line_rescuer/widgets/internet_connection.dart';

class CheckConnection extends ConsumerStatefulWidget {
  const CheckConnection({super.key});

  @override
  ConsumerState<CheckConnection> createState() => _CheckConnectionState();
}

class _CheckConnectionState extends ConsumerState<CheckConnection> {
  @override
  Widget build(BuildContext context) {
    final route = ref.watch(appRouterProvider);

    return _buildRouteWidget(route);
  }

  Widget _buildRouteWidget(AppRoute route) {
    switch (route) {
      case AppRoute.loading:
        return _loadingScreen();
      case AppRoute.login:
        return const InternetConnection(child: RescuerOnboarding());
      case AppRoute.blocked:
        final user = FirebaseAuth.instance.currentUser;
        return RescuerOnlineStatus(
          child: RescuerBlockedDialog(email: user?.email ?? ''),
        );
      case AppRoute.maintenance:
        return const RescuerOnlineStatus(child: MaintenancePage());
      case AppRoute.home:
        return const InternetConnection(
          child: RescuerOnlineStatus(child: InOutCalls(child: LandingPage())),
        );
    }
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
