import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'package:life_line_rescuer/pages/rescuer_map_page.dart';
import 'package:life_line_rescuer/providers/missions_card_provider.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/utils/responsive_helper.dart';
import 'package:life_line_rescuer/widgets/global/page_loading.dart';
import 'package:life_line_rescuer/widgets/global/page_message.dart';
import 'package:life_line_rescuer/widgets/global/page_navigation.dart';
import 'dart:io' show Platform;

class MissionsCardSheet {
  static void show(BuildContext context, {List<String>? assignments}) {
    showModalBottomSheet(
      isDismissible: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MissionSheet(assigned: assignments),
    );
  }
}

class MissionSheet extends ConsumerStatefulWidget {
  final List<String>? assigned;
  const MissionSheet({super.key, this.assigned});

  @override
  ConsumerState<MissionSheet> createState() => _MissionSheetState();
}

class _MissionSheetState extends ConsumerState<MissionSheet> {
  FirebaseFirestore? _victimFirestore;
  final List<StreamSubscription> _victimSubscriptions = [];

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

  @override
  void dispose() {
    for (final subscription in _victimSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _initSecondaryFirebase() async {
    try {
      if (!mounted) return;
      ref.read(globalPageProvider.notifier).setIsLoading(true);

      FirebaseApp victimApp;
      // Victim Firebase
      try {
        victimApp = Firebase.app('project-life-line');
      } catch (_) {
        victimApp = await Firebase.initializeApp(
          name: 'project-life-line',
          options: Platform.isIOS ? _victimIosOptions : _victimAndroidOptions,
        );
      }

      _victimFirestore = FirebaseFirestore.instanceFor(app: victimApp);

      _listenToVictimData();

      if (!mounted) return;
      ref.read(globalPageProvider.notifier).setIsLoading(false);
    } catch (e) {
      if (!mounted) return;
      ref.read(globalPageProvider.notifier).setIsLoading(false);
      pageMessage(
        'Failed to load victim data, Please try again',
        context,
        AppColors.error,
      );
      pageNavigation(const LandingPage(), context);
    }
  }

  void _listenToVictimData() {
    if (_victimFirestore == null || widget.assigned == null) return;

    try {
      // Cancel existing subscriptions
      for (final subscription in _victimSubscriptions) {
        subscription.cancel();
      }
      _victimSubscriptions.clear();

      // Start with an empty list
      if (mounted) {
        ref.read(globalPageProvider.notifier).setVictims([]);
      }

      for (final uid in widget.assigned!) {
        final subscription = _victimFirestore!
            .collection('users')
            .doc(uid)
            .snapshots()
            .listen((docSnapshot) {
              if (!mounted) return;

              if (!docSnapshot.exists) return;

              final data = docSnapshot.data();

              // Ignore all non-approved requests
              if (data?['requestAccepted'] != 'accepted') {
                return;
              }

              final updatedVictim = {
                'uid': uid,
                'name': data?['name'] ?? 'N/A',
                'severity': data?['severity'] ?? 'N/A',
                'location': data?['location'] ?? 'N/A',
                'disasterType': data?['disasterType'] ?? 'N/A',
                'online': data?['online'] ?? false,
                'latitude': data?['latitude'] ?? 0.0,
                'longitude': data?['longitude'] ?? 0.0,
              };

              if (!mounted) return;
              final currentVictims = ref.read(globalPageProvider).victims;

              // Remove old version of this victim if it exists
              final updatedList =
                  currentVictims
                      .where((victim) => victim['uid'] != uid)
                      .toList();

              // Add the latest approved version
              updatedList.add(updatedVictim);

              if (!mounted) return;
              ref.read(globalPageProvider.notifier).setVictims(updatedList);
            });

        _victimSubscriptions.add(subscription);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.softBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              width: ResponsiveHelper.contentWidth(context),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.isTablet(context) ? 32 : 16,
                      vertical: ResponsiveHelper.isTablet(context) ? 24 : 16,
                    ),
                    child: Text(
                      'My Missions',
                      style: AppText.subtitle.copyWith(
                        fontSize: ResponsiveHelper.titleFont(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Body
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        return _buildBody(ref);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              return _buildLoadingOverlay(ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();

    final isLoading = ref.watch(globalPageProvider.select((v) => v.isLoading));
    if (isLoading) {
      return const SizedBox.shrink();
    }

    final victims = ref.watch(globalPageProvider.select((v) => v.victims));

    if (victims.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.isTablet(context) ? 48 : 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                color: AppColors.textSecondary.withOpacity(0.5),
                size: ResponsiveHelper.isTablet(context) ? 96 : 64,
              ),
              SizedBox(height: ResponsiveHelper.isTablet(context) ? 24 : 16),
              Text(
                'No missions assigned',
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
        return Consumer(
          builder: (context, ref, child) {
            return _buildMissionCard(victims[index], ref);
          },
        );
      },
    );
  }

  Widget _buildLoadingOverlay(WidgetRef ref) {
    if (!context.mounted) return const SizedBox.shrink();
    final isLoading = ref.watch(globalPageProvider.select((v) => v.isLoading));

    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return pageLoading(context);
  }

  Widget _buildMissionCard(Map<String, dynamic> victim, WidgetRef ref) {
    final name = victim['name'] ?? 'N/A';
    final severity = victim['severity'] ?? 'N/A';
    final location = victim['location'] ?? 'N/A';
    final disasterType = victim['disasterType'] ?? 'N/A';
    final uid = victim['uid'] ?? '';
    final isOnline = victim['online'] ?? false;
    final latitude = victim['latitude'] ?? 0.0;
    final longitude = victim['longitude'] ?? 0.0;
    if (!mounted) return const SizedBox.shrink();
    final isExpanded = ref.watch(victimCardExpandedProvider(uid));

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
      child: Column(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                if (mounted) {
                  ref.read(victimCardExpandedProvider(uid).notifier).state =
                      !isExpanded;
                }
              },
              child: Container(
                padding: EdgeInsets.all(
                  ResponsiveHelper.isTablet(context) ? 32 : 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Online/offline status ball
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? Colors.green : Colors.red,
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveHelper.isTablet(context) ? 18 : 16,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppText.fieldLabel.copyWith(
                              fontSize:
                                  ResponsiveHelper.isTablet(context) ? 20 : 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkCharcoal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location,
                            style: AppText.small.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: ResponsiveHelper.bodyFont(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.location_on,
                        color: AppColors.primaryMaroon,
                        size: ResponsiveHelper.iconSize(context),
                      ),
                      onPressed: () {
                        pageNavigation(
                          RescuerMapPage(
                            latitude: latitude,
                            longitude: longitude,
                            victimUid: uid,
                          ),
                          context,
                        );
                      },
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                        size: ResponsiveHelper.isTablet(context) ? 32 : 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isExpanded ? 1.0 : 0.0,
              child:
                  isExpanded
                      ? Container(
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveHelper.isTablet(context) ? 32 : 24,
                          0,
                          ResponsiveHelper.isTablet(context) ? 32 : 24,
                          ResponsiveHelper.isTablet(context) ? 32 : 24,
                        ),
                        child: _buildExpandedDetails(
                          severity,
                          disasterType,
                          location,
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(
    String severityDisplay,
    String disasterType,
    String location,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: ResponsiveHelper.isTablet(context) ? 24 : 16,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Mission Details'),
          SizedBox(height: ResponsiveHelper.isTablet(context) ? 16 : 12),
          _buildDetailRow(
            'Emergency Type',
            severityDisplay,
            Icons.warning_amber_outlined,
          ),
          _buildDetailRow(
            'Disaster Type',
            disasterType,
            Icons.health_and_safety_outlined,
          ),
          _buildDetailRow('Location', location, Icons.location_on_outlined),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppText.fieldLabel.copyWith(
        fontSize: ResponsiveHelper.isTablet(context) ? 18 : 14,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryMaroon,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveHelper.isTablet(context) ? 16 : 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: ResponsiveHelper.isTablet(context) ? 24 : 22,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: ResponsiveHelper.isTablet(context) ? 12 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.small.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: ResponsiveHelper.isTablet(context) ? 14 : 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: AppText.small.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: ResponsiveHelper.bodyFont(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
