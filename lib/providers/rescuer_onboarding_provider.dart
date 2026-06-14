import 'package:flutter_riverpod/legacy.dart';

final selectedNgoIdProvider = StateProvider.autoDispose<String?>((ref) => null);

class RescuePageNotifier extends StateNotifier<RescuePageState> {
  RescuePageNotifier()
    : super(
        RescuePageState(
          isLoading: false,
          approvedNgos: [],
          selectedNgo: null,
          isDropdownExpanded: false,
          isSubmitting: false,
          googleAuthenticated: false,
        ),
      );
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setApprovedNgos(List<Map<String, dynamic>> ngos) {
    state = state.copyWith(approvedNgos: ngos);
  }

  void setSelectedNgo(String? ngoId) {
    state = state.copyWith(selectedNgo: ngoId);
  }

  void setIsDropdownExpanded(bool isExpanded) {
    state = state.copyWith(isDropdownExpanded: isExpanded);
  }

  void setIsSubmitting(bool isSubmitting) {
    state = state.copyWith(isSubmitting: isSubmitting);
  }

  void setGoogleAuthenticated(bool isAuthenticated) {
    state = state.copyWith(googleAuthenticated: isAuthenticated);
  }
}

class RescuePageState {
  final bool isLoading;
  final List<Map<String, dynamic>> approvedNgos;
  final String? selectedNgo;
  final bool isDropdownExpanded;
  final bool isSubmitting;
  final bool googleAuthenticated;

  RescuePageState({
    this.isLoading = false,
    this.approvedNgos = const [],
    this.selectedNgo,
    this.isDropdownExpanded = false,
    this.isSubmitting = false,
    this.googleAuthenticated = false,
  });

  RescuePageState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? approvedNgos,
    String? selectedNgo,
    bool? isDropdownExpanded,
    bool? isSubmitting,
    bool? googleAuthenticated,
  }) {
    return RescuePageState(
      isLoading: isLoading ?? this.isLoading,
      approvedNgos: approvedNgos ?? this.approvedNgos,
      selectedNgo: selectedNgo ?? this.selectedNgo,
      isDropdownExpanded: isDropdownExpanded ?? this.isDropdownExpanded,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      googleAuthenticated: googleAuthenticated ?? this.googleAuthenticated,
    );
  }
}

final rescueOnboardingProvider =
    StateNotifierProvider<RescuePageNotifier, RescuePageState>(
      (ref) => RescuePageNotifier(),
    );
