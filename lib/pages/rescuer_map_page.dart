import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:life_line_rescuer/config/map_routes_api.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
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
import 'dart:developer' as developer;

import 'package:life_line_rescuer/widgets/global/page_navigation.dart';

class RescuerMapPage extends ConsumerStatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? victimUid; 
  const RescuerMapPage({super.key, required this.latitude, required this.longitude, required this.victimUid});

  @override
  ConsumerState<RescuerMapPage> createState() => _RescuerMapPageState();
}

class _RescuerMapPageState extends ConsumerState<RescuerMapPage> {
  final MapController _mapController = MapController();
  late LocationSettings locationSettings;
  StreamSubscription<Position>? _locationSubscription;
  bool _isMarkingArrived = false;
  
  @override
  void initState() {
    super.initState();
    developer.log('PAGE VICTIM LAT: ${widget.latitude}');
    developer.log('PAGE VICTIM LNG: ${widget.longitude}');
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
    developer.log('RESCUER LONGITUDE: $rescuerLng');
    developer.log('RESCUER LATITUDE: $rescuerLat');
    developer.log('VICTIM LONGITUDE: ${widget.longitude}');
    developer.log('VICTIM LATITUDE: ${widget.latitude}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List coordinates = data['features'][0]['geometry']['coordinates'];
      final summary = data['features'][0]['properties']['segments'][0];
      final distanceKm = (summary['distance'] / 1000).toStringAsFixed(1);
      final durationMin = (summary['duration'] / 60).toStringAsFixed(0);

      if (mounted) {
        ref.read(routePointsProvider.notifier).state = coordinates
            .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
            .toList();
        ref.read(rescuerMapProvider.notifier).setDistance('$distanceKm km');
        ref.read(rescuerMapProvider.notifier).setDuration('$durationMin min');
        _mapController.move(
          LatLng(rescuerLat, rescuerLng),
          15,
        );
      }
    }
  } catch (e) {
    pageMessage('Failed to construct poly lines, Please retry', context, AppColors.error);
    pageNavigation(const LandingPage(), context);
  }
}

  Future<void> _startLocationTracking() async {
    try {
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
          // ✅ Check if rescuer has reached the victim
          if (widget.latitude != null && widget.longitude != null) {
            final distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              widget.latitude!,
              widget.longitude!,
            );
            // within 50 meters = reached victim
            if (distance <= 50 && mounted) {
              _locationSubscription?.cancel();
              _showArrivedDialog();
            }
          }
        }
      },
      onError: (e) {
        // ignore error
      },
    );
    }catch (e) {
      pageMessage('Location tracking service failed, Please retry', context, AppColors.error);
      pageNavigation(const LandingPage(), context);
    }
  }

  Future<void> _markRescuerArrived() async {
  if (widget.victimUid == null) return;
  try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.victimUid)
              .get();
      if (userDoc.exists) {
         await FirebaseFirestore.instance.collection('users')
        .doc(widget.victimUid)
        .set({'rescuerArrived': true}, SetOptions(merge: true));
      }
  } catch (e) {
    pageMessage('An unexpected error occurred, Please retry', context, AppColors.error);
    pageNavigation(const LandingPage(), context);
  }
}

void _showArrivedDialog() {
  if (!mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderColor, width: 1),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryMaroon.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.primaryMaroon,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Victim Reached',
              textAlign: TextAlign.center,
              style: AppText.formTitle,
            ),
          ],
        ),
        content: const Text(
          'You have arrived at the victim\'s location. Please proceed with assistance.',
          textAlign: TextAlign.center,
          style: AppText.formDescription,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: AppButtons.submit,
              onPressed: _isMarkingArrived
                  ? null
                  : () async {
                      setDialogState(() => _isMarkingArrived = true);
                      await _markRescuerArrived();
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      setDialogState(() => _isMarkingArrived = false);
                    },
              child: _isMarkingArrived
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Okay', style: AppText.submitButton),
            ),
          ),
        ],
      ),
    ),
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
              address, latitude, longitude);
        }
      }
    } catch (e) {
      pageMessage('An unexpected error occurred, Please retry', context, AppColors.error);
      pageNavigation(const LandingPage(), context);
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
            fetchedResult.latitude, fetchedResult.longitude);
      }
    } catch (e) {
      pageMessage('Failed to extract location, Please retry', context, AppColors.error);
      pageNavigation(const LandingPage(), context);
    }
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
                  Consumer(
                    builder:(context, ref, child) {
                      if(!mounted) return const SizedBox.shrink();
                      final distance = ref.watch(rescuerMapProvider.select((state) => state.distance));
                      if(!mounted) return const SizedBox.shrink();
                      final duration = ref.watch(rescuerMapProvider.select((state) => state.duration));

                      if (distance.isEmpty && duration.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                      top: ResponsiveHelper.isTablet(context) ? 32 : 16,
                      left: ResponsiveHelper.isTablet(context) ? 32 : 16,
                      right: ResponsiveHelper.isTablet(context) ? 32 : 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.route, color: AppColors.primaryMaroon, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  distance,
                                  style: AppText.small.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 20, color: AppColors.borderColor),
                            Row(
                              children: [
                                const Icon(Icons.access_time, color: AppColors.primaryMaroon, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  duration,
                                  style: AppText.small.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                    },
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