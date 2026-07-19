import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_riverpod/legacy.dart';

// Keep track of the current active call session ID
final currentCallIdProvider = StateProvider<String?>((ref) => null);

// Streams the current active call document to monitor its live status
final currentCallDocStreamProvider = StreamProvider<DocumentSnapshot?>((ref) {
  final callId = ref.watch(currentCallIdProvider);

  if (callId == null) return Stream.value(null);

  return FirebaseFirestore.instance.collection('calls').doc(callId).snapshots();
});
