import 'package:flutter_riverpod/legacy.dart';

class RequestsPageNotifier extends StateNotifier<RequestsPageState> {
  RequestsPageNotifier()
    : super(RequestsPageState(isLoading: false, victims: []));

  void setIsLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void setVictims(List<Map<String, dynamic>> victims) {
    state = state.copyWith(victims: victims);
  }
}

class RequestsPageState {
  final bool isLoading;
  final List<Map<String, dynamic>> victims;

  RequestsPageState({this.isLoading = false, this.victims = const []});

  RequestsPageState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? victims,
  }) {
    return RequestsPageState(
      victims: victims ?? this.victims,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final requestsPageProvider =
    StateNotifierProvider<RequestsPageNotifier, RequestsPageState>(
      (ref) => RequestsPageNotifier(),
    );
