import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:life_line_rescuer/config/heigit_api.dart';
import 'package:life_line_rescuer/providers/rescuer_map_provider.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:life_line_rescuer/services/location_service.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/utils/responsive_helper.dart';
import 'package:life_line_rescuer/widgets/fetch_lat_long.dart';
import 'package:life_line_rescuer/widgets/global/bottom_navbar.dart';
import 'package:life_line_rescuer/widgets/global/page_message.dart';
class RescuerMapPage extends ConsumerStatefulWidget {
  final double? latitude;
  final double? longitude;
  const RescuerMapPage({super.key, required this.latitude, required this.longitude});

  @override
  ConsumerState<RescuerMapPage> createState() => _RescuerMapPageState();
}

class _RescuerMapPageState extends ConsumerState<RescuerMapPage> {
  final MapController _mapController = MapController();
  late LocationSettings locationSettings;
  StreamSubscription<Position>? _locationSubscription;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getLocation();
      await _startLocationTracking();
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _drawRoute(double rescuerLat, double rescuerLng) async {
  if (widget.latitude == null || widget.longitude == null) return;

  try {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car'
      '?api_key=${HeigitApi.orsApiKey}'
      '&start=$rescuerLng,$rescuerLat'
      '&end=${widget.longitude},${widget.latitude}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List coordinates = data['features'][0]['geometry']['coordinates'];

      if (mounted) {
        ref.read(routePointsProvider.notifier).state = coordinates
            .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
            .toList();
      }
    }
  } catch (e) {
    // ignore
  }
}

  Future<void> _startLocationTracking() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 10),
        forceLocationManager: false,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'LifeLine is active',
          notificationText: 'Sharing location for emergency assistance',
          enableWakeLock: false,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: true,
      );
    }

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        final newPosition = LatLng(position.latitude, position.longitude);
        if (mounted) {
          _mapController.move(newPosition, _mapController.camera.zoom);
          await _updateLocationInFirestore(
              position.latitude, position.longitude);
        }
      },
      onError: (e) {
        // silently ignore — permission already checked above
      },
    );
  }

  Future<void> _updateLocationInFirestore(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        if (address.isNotEmpty) {
          await LocationService.updateUserLocation(
              address, latitude.toString(), longitude.toString());
        }
      }
    } catch (e) {
      // ignore error
    }
  }

  Future<void> getLocation() async {
    try {
      LocationResult fetchedResult = await fetchLatLong();
      if (fetchedResult.error != null) {
        pageMessage(fetchedResult.error!, context, AppColors.error);
        return;
      }
      _mapController.move(
        LatLng(fetchedResult.latitude, fetchedResult.longitude),
        15,
      );

      await _drawRoute(fetchedResult.latitude, fetchedResult.longitude);

      if (fetchedResult.address != null && fetchedResult.address!.isNotEmpty) {
        await LocationService.updateUserLocation(fetchedResult.address,
            fetchedResult.latitude.toString(), fetchedResult.longitude.toString());
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: ResponsiveHelper.contentWidth(context),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          ResponsiveHelper.horizontalPadding(context),
                      vertical: ResponsiveHelper.verticalPadding(context),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.isTablet(context) ? 24 : 16,
                      ),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: LatLng(34.1463, 73.2117),
                          initialZoom: 15,
                          minZoom: 1,
                          maxZoom: 18,
                          interactionOptions: InteractionOptions(
                            flags: InteractiveFlag.pinchZoom |
                                InteractiveFlag.drag |
                                InteractiveFlag.doubleTapZoom,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.lifeline.app',
                          ),
                          // If a victim location is provided, show a red marker
                          if (widget.latitude != null && widget.longitude != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(widget.latitude!, widget.longitude!),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                              Consumer(
                                builder:(context, ref, child) {
                                  if(!mounted) return const SizedBox.shrink();
                                  final routePoints = ref.watch(routePointsProvider);
                                  if (routePoints.isNotEmpty) {
                                    return PolylineLayer(
                                      polylines: [
                                        Polyline(
                                          points: routePoints,
                                          strokeWidth: 4.0,
                                          color: Colors.red,
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                          const CurrentLocationLayer(
                            style: LocationMarkerStyle(
                              marker: DefaultLocationMarker(
                                color: AppColors.primaryMaroon,
                              ),
                              markerSize: Size(20, 20),
                              markerDirection: MarkerDirection.heading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: ResponsiveHelper.isTablet(context) ? 32 : 16,
                  bottom: ResponsiveHelper.isTablet(context) ? 32 : 16,
                  child: FloatingActionButton(
                    heroTag: 'currentLocation',
                    backgroundColor: AppColors.primaryMaroon,
                    child: Icon(
                      Icons.my_location,
                      color: AppColors.white,
                      size: ResponsiveHelper.iconSize(context),
                    ),
                    onPressed: ()  {

                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavbar(currentIndex: 1),
    );
  }
}