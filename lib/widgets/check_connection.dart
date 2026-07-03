import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'package:life_line_rescuer/pages/offline_connectivity.dart';
import 'package:life_line_rescuer/pages/rescuer_blocked.dart';
import 'package:life_line_rescuer/pages/rescuer_onboarding.dart';
import 'package:life_line_rescuer/providers/app_router_provider.dart';
import 'package:life_line_rescuer/styles/styles.dart';

class CheckConnection extends ConsumerStatefulWidget {
  const CheckConnection({super.key});

  @override
  ConsumerState<CheckConnection> createState() => _CheckConnectionState();
}

class _CheckConnectionState extends ConsumerState<CheckConnection>
    with WidgetsBindingObserver {
  FirebaseFirestore? _ngoFirestore;

  // life-line-ngo database credentials
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
    _updateOnlineStatus(false);
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

      _ngoFirestore = FirebaseFirestore.instanceFor(app: ngoApp);
    } catch (e) {
      // Ignore Firestore initialization errors.
    }
  }

  Future<void> _updateOnlineStatus(bool online) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'online': online,
      }, SetOptions(merge: true));

      if (_ngoFirestore == null) {
        await _initNgoFirestore();
      }

      if (_ngoFirestore == null) return;

      final rescuerDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!rescuerDoc.exists) return;

      final data = rescuerDoc.data();
      final ngoId = data?['ngoId'];

      if (ngoId == null) return;

      await _ngoFirestore!
          .collection('ngo-info-database')
          .doc(ngoId)
          .collection('rescuer-requests')
          .doc(user.uid)
          .set({'online': online}, SetOptions(merge: true));
    } catch (_) {
      // Ignore Firestore update errors.
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

  @override
  Widget build(BuildContext context) {
    final route = ref.watch(appRouterProvider);

    switch (route) {
      case AppRoute.loading:
        return _loadingScreen();
      case AppRoute.offline:
        return const OfflineConnectivity();
      case AppRoute.login:
        return const RescuerOnboarding();
      case AppRoute.blocked:
        final user = FirebaseAuth.instance.currentUser;
        return RescuerBlockedDialog(email: user?.email ?? '');
      case AppRoute.home:
        return const LandingPage();
    }
  }

  Widget _loadingScreen() {
    return Scaffold(
      body: Container(
        decoration: AppContainers.pageContainer,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryMaroon),
        ),
      ),
    );
  }
}
