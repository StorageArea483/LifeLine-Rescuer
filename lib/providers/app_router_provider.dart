import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/providers/auth_provider.dart';
import 'package:life_line_rescuer/providers/internet_provider.dart';
import 'package:life_line_rescuer/providers/rescuer_access_provider.dart';

enum AppRoute { loading, offline, login, blocked, home }

final appRouterProvider = Provider<AppRoute>((ref) {
  final auth = ref.watch(authStateProvider);
  final internet = ref.watch(internetProvider);
  final userStatus = ref.watch(rescuerAccessProvider);

  // Loading
  if (auth.isLoading || internet.isLoading || userStatus.isLoading) {
    return AppRoute.loading;
  }

  // Offline
  final connectivity = internet.value;
  if (connectivity == null || connectivity.contains(ConnectivityResult.none)) {
    return AppRoute.offline;
  }

  // Login
  final user = auth.value;
  if (user == null) {
    return AppRoute.login;
  }

  // User Status
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

  return AppRoute.home;
});
