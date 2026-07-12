import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/models/admin_settings.dart';

// Firebase configuration for life-line-admin
const FirebaseOptions _rescuerFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyCEoP-ISJx1dn1EM7Pt3ikEXlSCkmcpMLY',
  appId: '1:135703361476:web:3a4d9e2ec37c8e3d125691',
  messagingSenderId: '135703361476',
  projectId: 'life-line-admin',
  authDomain: 'life-line-admin.firebaseapp.com',
  storageBucket: 'life-line-admin.firebasestorage.app',
);

final adminSettingsStreamProvider = StreamProvider<AdminSettings>((ref) async* {
  // outer stream
  FirebaseApp rescuerApp;
  try {
    rescuerApp = Firebase.app('life-line-admin');
  } catch (_) {
    rescuerApp = await Firebase.initializeApp(
      name: 'life-line-admin',
      options: _rescuerFirebaseOptions,
    );
  }

  /* The data is passed from inner stream back to outer stream and outer stream updates the UI
    because it is a Stream Provider */
  yield* FirebaseFirestore.instanceFor(
    // inner stream
    app: rescuerApp,
  ).collection('settings').snapshots().map((snapshot) {
    if (snapshot.docs.isEmpty) {
      return const AdminSettings(maintenance: false);
    }

    final data = snapshot.docs.first.data();
    return AdminSettings(maintenance: data['rescuer maintenance'] ?? false);
  });
});
