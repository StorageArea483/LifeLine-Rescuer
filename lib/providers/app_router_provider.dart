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

  // Loading
  if (internet.isLoading || userStatus.isLoading || settings.isLoading) {
    return AppRoute.loading;
  }

  // Offline
  final connectivity = internet.value;
  if (connectivity == null || connectivity.contains(ConnectivityResult.none)) {
    return AppRoute.offline;
  }

  // User Status
  final status = userStatus.value;
  if (status == null) {
    return AppRoute.login;
  }

  if (status.blocked) {
    return AppRoute.blocked;
  }

  // Admin Settings
  final admin = settings.value;

  if (admin == null) {
    return AppRoute.loading;
  }

  if (admin.maintenance) {
    return AppRoute.maintenance;
  }

  if (!status.approved) {
    return AppRoute.login;
  }

  return AppRoute.home;
});
