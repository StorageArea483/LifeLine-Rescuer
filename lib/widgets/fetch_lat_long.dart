import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String? address;
  final String? error;

  LocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.error,
  });
}

Future<LocationResult> fetchLatLong() async {
  try {
    // STEP 1: Check permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // STEP 2: Request permission if denied
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // STEP 3: If still denied → return error
    if (permission == LocationPermission.denied) {
      return LocationResult(
        latitude: 0.0,
        longitude: 0.0,
        error: 'Location permission is required.',
      );
    }

    // STEP 4: If permanently denied → return error
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return LocationResult(
        latitude: 0.0,
        longitude: 0.0,
        error:
            'Permission permanently denied. Please enable it in app settings.',
      );
    }

    // STEP 5: Fetch current position
    Position position = await Geolocator.getCurrentPosition();

    // STEP 6: Convert coordinates to address using reverse geocoding
    String? addressString;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Build address string from available components
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          addressParts.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        addressString = addressParts.join(', ');
      }
    } catch (e) {
      // If reverse geocoding fails, use coordinates as fallback
      addressString =
          'Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}';
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      address: addressString,
    );
  } catch (e) {
    return LocationResult(
      latitude: 0.0,
      longitude: 0.0,
      error: 'Failed to get location',
    );
  }
}
