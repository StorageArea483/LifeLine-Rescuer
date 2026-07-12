import 'package:flutter_riverpod/legacy.dart';

final rescuerContactLoadingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

final assignedVictimsProvider =
    StateProvider.autoDispose<List<Map<String, dynamic>>>((ref) => []);
