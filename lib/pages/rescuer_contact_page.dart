import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'dart:io' show Platform;

import 'package:life_line_rescuer/providers/rescuer_contact_provider.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/utils/responsive_helper.dart';
import 'package:life_line_rescuer/widgets/global/bottom_navbar.dart';
import 'package:life_line_rescuer/widgets/global/page_loading.dart';
import 'package:life_line_rescuer/widgets/global/page_message.dart';
import 'package:life_line_rescuer/widgets/global/page_navigation.dart';
import 'package:life_line_rescuer/widgets/global/rescuer_chat_screen.dart';

class RescuerContactPage extends ConsumerStatefulWidget {
  const RescuerContactPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RescuerContactPageState();
}

class _RescuerContactPageState extends ConsumerState<RescuerContactPage> {
  FirebaseFirestore? victimFirestore;

  // life-line-victim database credentials
  static const FirebaseOptions _victimAndroidOptions = FirebaseOptions(
    apiKey: 'AIzaSyByihQ3YBdrJUrAAxFSX3257fUMa0AJ6uo',
    appId: '1:503939690280:android:aff06bb9fb777faf792a1d',
    messagingSenderId: '503939690280',
    projectId: 'project-life-line',
    storageBucket: 'project-life-line.firebasestorage.app',
  );

  static const FirebaseOptions _victimIosOptions = FirebaseOptions(
    apiKey: 'AIzaSyBDX51z8C6yiZnbEHgHK70UxnRZcn5oSd0',
    appId: '1:503939690280:ios:ed2fb1d85f841609792a1d',
    messagingSenderId: '503939690280',
    projectId: 'project-life-line',
    storageBucket: 'project-life-line.firebasestorage.app',
    iosBundleId: 'com.example.lifeLine',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSecondaryFirebase();
    });
  }

  Future<void> _initSecondaryFirebase() async {
    if (mounted) {
      ref.read(rescuerContactLoadingProvider.notifier).state = true;
    }
    try {
      FirebaseApp rescuerApp;

      // Victim Firebase
      try {
        rescuerApp = Firebase.app('project-life-line');
      } catch (_) {
        rescuerApp = await Firebase.initializeApp(
          name: 'project-life-line',
          options: Platform.isIOS ? _victimIosOptions : _victimAndroidOptions,
        );
      }

      victimFirestore = FirebaseFirestore.instanceFor(app: rescuerApp);

      await _fetchAssignedVictims();

      if (mounted) {
        ref.read(rescuerContactLoadingProvider.notifier).state = false;
      }
    } catch (e) {
      if (mounted) {
        ref.read(rescuerContactLoadingProvider.notifier).state = false;
        pageMessage(
          'An unexpected error occurred. Please try again.',
          context,
          AppColors.error,
        );
        pageNavigation(const LandingPage(), context);
      }
    }
  }

  Future<void> _fetchAssignedVictims() async {
    if (victimFirestore == null) return;

    try {
      final rescuerId = FirebaseAuth.instance.currentUser?.uid;
      if (rescuerId == null) return;

      final rescuerDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(rescuerId)
              .get();

      if (!rescuerDoc.exists) return;

      final assigned = rescuerDoc.data()?['assigned'] as Map<String, dynamic>?;
      if (assigned == null || assigned.isEmpty) return;

      final victims = <Map<String, dynamic>>[];

      for (final entry in assigned.entries) {
        final victimId = entry.key;
        final severity = entry.value ?? 'N/A';

        final victimDoc =
            await victimFirestore!.collection('users').doc(victimId).get();

        if (!victimDoc.exists) continue;

        final data = victimDoc.data()!;

        victims.add({
          'id': victimDoc.id,
          'name': data['name'] ?? 'N/A',
          'photoURL': data['photoURL'] ?? '',
          'online': data['online'] ?? false,
          'severity': severity,
        });
      }

      if (mounted) {
        ref.read(assignedVictimsProvider.notifier).state = victims;
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        iconTheme: IconThemeData(
          size: ResponsiveHelper.iconSize(context),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'Contacts',
          style: AppText.appHeader.copyWith(
            fontSize: ResponsiveHelper.isTablet(context) ? 24 : 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: ResponsiveHelper.contentWidth(context),
            child: Consumer(
              builder: (context, ref, child) {
                return _buildBody(ref);
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavbar(currentIndex: 2),
    );
  }

  Widget _buildBody(WidgetRef ref) {
    final isLoading = ref.watch(rescuerContactLoadingProvider);
    final victims = ref.watch(assignedVictimsProvider);

    if (isLoading) {
      return pageLoading(context);
    }

    if (victims.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.isTablet(context) ? 48 : 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_search_outlined,
                color: AppColors.textSecondary.withOpacity(0.5),
                size: ResponsiveHelper.isTablet(context) ? 96 : 64,
              ),
              SizedBox(height: ResponsiveHelper.isTablet(context) ? 24 : 16),
              Text(
                'No victims assigned yet',
                style: AppText.subtitle.copyWith(
                  fontSize: ResponsiveHelper.titleFont(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveHelper.isTablet(context) ? 32 : 16),
      itemCount: victims.length,
      itemBuilder: (context, index) {
        return _buildVictimCard(victims[index]);
      },
    );
  }

  Widget _buildVictimCard(Map<String, dynamic> victim) {
    final name = victim['name'] ?? 'N/A';
    final photoURL = victim['photoURL'] ?? '';
    final bool isOnline = victim['online'] ?? false;
    final severity = victim['severity'] ?? 'N/A';
    final avatarSize = ResponsiveHelper.isTablet(context) ? 72.0 : 48.0;

    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.isTablet(context) ? 24 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryMaroon.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          pageNavigation(
            RescuerChatScreen(
              victimId: victim['id'] ?? '',
              victimName: name,
              photoUrl: photoURL,
            ),
            context,
          );
        },
        child: ListTile(
          contentPadding: EdgeInsets.all(
            ResponsiveHelper.isTablet(context) ? 24 : 16,
          ),
          leading: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundColor: AppColors.primaryMaroon.withOpacity(0.1),
                  backgroundImage:
                      photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                  child:
                      photoURL.isEmpty
                          ? Icon(
                            Icons.person,
                            color: AppColors.primaryMaroon,
                            size: avatarSize * 0.5,
                          )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: avatarSize * 0.28,
                    height: avatarSize * 0.28,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.success : AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceLight,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            name,
            style: AppText.fieldLabel.copyWith(
              fontSize: ResponsiveHelper.isTablet(context) ? 20 : 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: AppText.small.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: ResponsiveHelper.bodyFont(context),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• $severity',
                  style: AppText.small.copyWith(
                    color: AppColors.primaryMaroon,
                    fontSize: ResponsiveHelper.bodyFont(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.call,
              color: AppColors.primaryMaroon,
              size: ResponsiveHelper.iconSize(context),
            ),
            onPressed: () {
              // Calling logic to be implemented later
            },
          ),
        ),
      ),
    );
  }
}
