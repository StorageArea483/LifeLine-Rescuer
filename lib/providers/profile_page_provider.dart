import 'package:flutter_riverpod/legacy.dart';

// Provider for loading state
final profileLoadingProvider = StateProvider<bool>((ref) => false);

// Provider for user data
final userDataProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
