import 'package:flutter_riverpod/legacy.dart';

// Provider for loading state
final profileLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

// Provider for user data
final userDataProvider = StateProvider.autoDispose<Map<String, dynamic>?>(
  (ref) => null,
);
