import 'package:flutter/material.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'package:life_line_rescuer/pages/rescuer_map_page.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/widgets/global/page_navigation.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;

  const BottomNavbar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) {
          return;
        } else if (index == 0 && context.mounted) {
          pageNavigation(const LandingPage(), context);
        }else if (index == 1 && context.mounted) {
          pageNavigation(const RescuerMapPage(latitude: null, longitude: null), context);
        } else if (index == 2 && context.mounted) {
        } else if (index == 3 && context.mounted) {}
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.primaryMaroon,
      unselectedItemColor: AppColors.textSecondary,
      elevation: 4,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
