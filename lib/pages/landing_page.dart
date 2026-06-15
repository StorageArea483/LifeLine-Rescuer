import 'package:flutter/material.dart';
import 'package:life_line_rescuer/services/auth_service.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('Landing Page')),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () async {
          await GoogleSignInService.signOut();
        },
      ),
    );
  }
}
