import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final activeCallIdProvider = StateProvider<String?>((ref) => null);

final incomingCallStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('calls')
      .where('receiverId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'ringing')
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return null;
        }

        // Capture the most recent ringing call
        final doc = snapshot.docs.first;
        final data = doc.data();

        return {
          'callId': doc.id,
          'senderId': data['senderId'] ?? '',
          'receiverId': data['receiverId'] ?? '',
          'callerName': data['callerName'] ?? 'Unknown',
          'callerPhotoUrl': data['callerPhotoUrl'] ?? '',
          'audioOnly': data['audioOnly'] ?? false,
        };
      });
});
