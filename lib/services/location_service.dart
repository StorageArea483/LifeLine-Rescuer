import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  /// Update user location in Firestore
  static Future<void> updateUserLocation(String? address, double latitude, double longitude) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || address == null || address.isEmpty) return;

      final Map<String, dynamic> locationData = {'location': address, 'latitude': latitude, 'longitude': longitude};

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(locationData, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
}
