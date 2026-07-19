import 'package:flutter_riverpod/legacy.dart';

class GlobalPageNotifier extends StateNotifier<GlobalPageState> {
  GlobalPageNotifier() : super(GlobalPageState(isLoading: false, victims: []));

  void setIsLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void setVictims(List<Map<String, dynamic>> victims) {
    state = state.copyWith(victims: victims);
  }
}

class GlobalPageState {
  final bool isLoading;
  final List<Map<String, dynamic>> victims;

  GlobalPageState({this.isLoading = false, this.victims = const []});

  GlobalPageState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? victims,
  }) {
    return GlobalPageState(
      victims: victims ?? this.victims,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final globalPageProvider =
    StateNotifierProvider<GlobalPageNotifier, GlobalPageState>(
      (ref) => GlobalPageNotifier(),
    );

// Family provider to track each victim card's expanded state independently
final victimCardExpandedProvider = StateProvider.family
    .autoDispose<bool, String>((ref, victimId) => false);

// Family provider to track each victim's rescued state independently
final victimRescuedProvider = StateProvider.family.autoDispose<bool, String>(
  (ref, uid) => false,
);
