import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:life_line_rescuer/firebase_options.dart';
import 'package:life_line_rescuer/widgets/check_connection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
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

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: CheckConnection());
  }
}
