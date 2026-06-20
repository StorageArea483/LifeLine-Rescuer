import 'package:flutter_riverpod/legacy.dart';

class LanidngPageNotifier extends StateNotifier<LandingPageState> {
  LanidngPageNotifier()
    : super(LandingPageState(isLoading: false, activeRequests: {}));

  void setActiveRequests(Map<String, dynamic> requests) {
    state = state.copyWith(activeRequests: requests);
  }

  void setIsLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }
}

class LandingPageState {
  final bool isLoading;
  final Map<String, dynamic> activeRequests;

  LandingPageState({this.isLoading = false, this.activeRequests = const {}});

  LandingPageState copyWith({
    bool? isLoading,
    Map<String, dynamic>? activeRequests,
  }) {
    return LandingPageState(
      activeRequests: activeRequests ?? this.activeRequests,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final landingPageProvider =
    StateNotifierProvider.autoDispose<LanidngPageNotifier, LandingPageState>(
      (ref) => LanidngPageNotifier(),
    );
