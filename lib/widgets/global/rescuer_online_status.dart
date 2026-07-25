import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class RescuerOnlineStatus extends StatefulWidget {
  final Widget child;
  const RescuerOnlineStatus({super.key, required this.child});

  @override
  State<RescuerOnlineStatus> createState() => _VictimOnlineStatusState();
}

class _VictimOnlineStatusState extends State<RescuerOnlineStatus>
    with WidgetsBindingObserver {
  FirebaseFirestore? ngoFirestore;

  static const FirebaseOptions _ngoFirebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyBeieryGaw4bh4dtbrI54qsIc51XkP6SoM',
    appId: '1:169949190544:web:2640453ce5dd2aa55d3b15',
    messagingSenderId: '169949190544',
    projectId: 'life-line-ngo',
    authDomain: 'life-line-ngo.firebaseapp.com',
    storageBucket: 'life-line-ngo.firebasestorage.app',
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initNgoFirestore();
      await _updateOnlineStatus(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initNgoFirestore() async {
    try {
      FirebaseApp ngoApp;
      try {
        ngoApp = Firebase.app('life-line-ngo');
      } catch (_) {
        ngoApp = await Firebase.initializeApp(
          name: 'life-line-ngo',
          options: _ngoFirebaseOptions,
        );
      }

      ngoFirestore = FirebaseFirestore.instanceFor(app: ngoApp);
    } catch (e) {
      // ignore errors
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updateOnlineStatus(false);
    }
  }

  Future<void> _updateOnlineStatus(bool online) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'online': online},
      );

      if (ngoFirestore == null) {
        await _initNgoFirestore();
      }

      if (ngoFirestore == null) return;

      final rescuerDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!rescuerDoc.exists) return;

      final data = rescuerDoc.data();
      final ngoId = data?['ngoId'];

      if (ngoId == null) return;

      await ngoFirestore!
          .collection('ngo-info-database')
          .doc(ngoId)
          .collection('rescuer-requests')
          .doc(user.uid)
          .update({'online': online});
    } catch (_) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
