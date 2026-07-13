import 'package:flutter_riverpod/legacy.dart';

// Deterministic chat id between rescuer and victim
final rescuerChatIdProvider = StateProvider<String?>((ref) => null);

// Loading state while chat initializes
final rescuerChatLoadingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

// Messages for a given chatId
final rescuerChatMessagesProvider =
    StateProvider.family<List<Map<String, dynamic>>, String>(
      (ref, chatId) => [],
    );

// Live online/offline status of the victim, keyed by victimId
final victimOnlineStatusProvider = StateProvider.family<bool, String>(
  (ref, victimId) => false,
);

final victimReportProvider =
    StateProvider.family<Map<String, dynamic>?, String>(
      (ref, victimId) => null,
    );
