import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

class SecondaryFirebaseApps {
  static Future<void> initialize() async {
    await Future.wait([_initializeNgo(), _initializeVictim()]);
  }

  static Future<void> _initializeNgo() async {
    try {
      Firebase.app('life-line-ngo');
    } catch (_) {
      await Firebase.initializeApp(
        name: 'life-line-ngo',
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBeieryGaw4bh4dtbrI54qsIc51XkP6SoM',
          appId: '1:169949190544:web:2640453ce5dd2aa55d3b15',
          messagingSenderId: '169949190544',
          projectId: 'life-line-ngo',
          authDomain: 'life-line-ngo.firebaseapp.com',
          storageBucket: 'life-line-ngo.firebasestorage.app',
        ),
      );
    }
  }

  static Future<void> _initializeVictim() async {
    try {
      Firebase.app('life-line-victim');
    } catch (_) {
      await Firebase.initializeApp(
        name: 'life-line-victim',
        options:
            Platform.isIOS
                ? _victimFirebaseOptionsIOS
                : _victimFirebaseOptionsAndroid,
      );
    }
  }

  // Firebase configuration for life-line-victim
  static const FirebaseOptions _victimFirebaseOptionsAndroid = FirebaseOptions(
    apiKey: 'AIzaSyDxYe-nH3pXUrSg4djqulFbtinb9ITVzys',
    appId: '1:909144850972:android:3953621a9efff1297c55d9',
    messagingSenderId: '909144850972',
    projectId: 'life-line-victim-27aaa',
    storageBucket: 'life-line-victim-27aaa.firebasestorage.app',
  );

  static const FirebaseOptions _victimFirebaseOptionsIOS = FirebaseOptions(
    apiKey: 'AIzaSyBaHw4XgFxhYk2JLdLmqSSvqMarSgko0cI',
    appId: '1:909144850972:ios:190ecbb64dd78f667c55d9',
    messagingSenderId: '909144850972',
    projectId: 'life-line-victim-27aaa',
    storageBucket: 'life-line-victim-27aaa.firebasestorage.app',
    iosBundleId: 'com.example.lifeLine',
  );
}
