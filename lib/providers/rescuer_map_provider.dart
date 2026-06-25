import 'package:flutter_riverpod/legacy.dart';
import 'package:latlong2/latlong.dart';

final routePointsProvider = StateProvider<List<LatLng>>((ref) {
  return [];
});
