import 'package:flutter_riverpod/legacy.dart';

// Deterministic chat id between victim and NGO
final ngoChatIdProvider = StateProvider<String?>((ref) => null);

// Loading state while chat initializes
final ngoChatLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

// Messages for a given chatId
final ngoChatMessagesProvider =
    StateProvider.family<List<Map<String, dynamic>>, String>(
      (ref, chatId) => [],
    );
