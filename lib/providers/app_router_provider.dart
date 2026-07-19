import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/providers/admin_settings_provider.dart';
import 'package:life_line_rescuer/providers/internet_provider.dart';
import 'package:life_line_rescuer/providers/rescuer_access_provider.dart';

enum AppRoute { loading, offline, login, blocked, maintenance, home }

final appRouterProvider = Provider<AppRoute>((ref) {
  final internet = ref.watch(internetProvider);
  final userStatus = ref.watch(rescuerAccessProvider);
  final settings = ref.watch(adminSettingsStreamProvider);

  // Loading Checks
  if (internet.isLoading || userStatus.isLoading || settings.isLoading) {
    return AppRoute.loading;
  }

  // Offline Connectivity Checks
  final connectivity = internet.value;
  if (connectivity == null || connectivity.contains(ConnectivityResult.none)) {
    return AppRoute.offline;
  }

  // User Identity Status Checks
  final status = userStatus.value;
  if (status == null) {
    return AppRoute.login;
  }

  if (status.blocked) {
    return AppRoute.blocked;
  }

  if (!status.approved) {
    return AppRoute.login;
  }

  // Remote Admin Settings Configuration
  final admin = settings.value;
  if (admin == null) {
    return AppRoute.loading;
  }

  if (admin.maintenance) {
    return AppRoute.maintenance;
  }
  // Base Default Route
  return AppRoute.home;
});
