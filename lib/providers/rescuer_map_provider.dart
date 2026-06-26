import 'package:flutter_riverpod/legacy.dart';
import 'package:latlong2/latlong.dart';

final routePointsProvider = StateProvider.autoDispose<List<LatLng>>((ref) {
  return [];
});

class RescuerMapNotifier extends StateNotifier<RescuerMapState> {
  RescuerMapNotifier() : super(RescuerMapState(distance: '', duration: ''));

  void setIsLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void setDistance(String value) {
    state = state.copyWith(distance: value);
  }

  void setDuration(String value) {
    state = state.copyWith(duration: value);
  }
}
class RescuerMapState {
  final String distance;
  final String duration;

  RescuerMapState({
    this.distance = '',
    this.duration = '',
  });

  RescuerMapState copyWith({
    bool? isLoading,
    String? distance,
    String? duration,
  }) {
    return RescuerMapState(
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
    );
  }
}

final rescuerMapProvider =
    StateNotifierProvider.autoDispose<RescuerMapNotifier, RescuerMapState>(
      (ref) => RescuerMapNotifier(),
    );