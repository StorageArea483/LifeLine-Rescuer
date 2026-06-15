import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/models/rescuer_access_state.dart';

final rescuerAccessProvider = StreamProvider<RescuerAccessState>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    // Stream.value closes the stream after returning a single value
    return Stream.value(
      const RescuerAccessState(
        approved: false,
        blocked: false,
        firstName: '',
        lastName: '',
      ),
    );
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) {
          return const RescuerAccessState(
            approved: false,
            blocked: false,
            firstName: '',
            lastName: '',
          );
        }

        final data = doc.data()!;

        return RescuerAccessState(
          approved: data['status'] == 'approved',
          blocked: data['blocked'] == true,
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
        );
      });
});
