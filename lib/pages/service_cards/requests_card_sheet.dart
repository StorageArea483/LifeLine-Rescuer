import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'package:life_line_rescuer/providers/missions_card_provider.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/utils/responsive_helper.dart';
import 'package:life_line_rescuer/widgets/global/in_out_calls.dart';
import 'package:life_line_rescuer/widgets/global/page_loading.dart';
import 'package:life_line_rescuer/widgets/global/page_message.dart';
import 'package:life_line_rescuer/widgets/global/page_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;

class RequestsCardSheet {
  static void show(
    BuildContext context, {
    required int activeRequests,
    List<String>? assignmentIds,
  }) {
    showModalBottomSheet(
      isDismissible: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => InOutCalls(
            child: RequestSheet(
              activeRequests: activeRequests,
              assignmentIds: assignmentIds,
            ),
          ),
    );
  }
}

class RequestSheet extends ConsumerStatefulWidget {
  final int activeRequests;
  final List<String>? assignmentIds;
  const RequestSheet({
    super.key,
    required this.activeRequests,
    this.assignmentIds,
  });

  @override
  ConsumerState<RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends ConsumerState<RequestSheet> {
  FirebaseFirestore? _victimFirestore;
  FirebaseFirestore? ngoFirestore;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSecondaryFirebase();
    });
  }

  Future<void> _initSecondaryFirebase() async {
    try {
      if (!mounted) return;
      ref.read(globalPageProvider.notifier).setIsLoading(true);

      FirebaseApp victimApp;
      FirebaseApp ngoApp;

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

      // NGO Firebase
      try {
        ngoApp = Firebase.app('life-line-ngo');
      } catch (_) {
        ngoApp = await Firebase.initializeApp(
          name: 'life-line-ngo',
          options: _ngoFirebaseOptions,
        );
      }

      ngoFirestore = FirebaseFirestore.instanceFor(app: ngoApp);

      await fetchPendingRequests();
    } catch (e) {
      if (!mounted) return;
      ref.read(globalPageProvider.notifier).setIsLoading(false);
      pageMessage(
        'Failed to load victim data, Please try again',
        context,
        AppColors.error,
      );
      pageNavigation(const InOutCalls(child: LandingPage()), context);
    }
  }

  Future<void> fetchPendingRequests() async {
    if (_victimFirestore == null || widget.assignmentIds == null) {
      if (mounted) ref.read(globalPageProvider.notifier).setIsLoading(false);
      return;
    }

    try {
      final List<Map<String, dynamic>> pending = [];

      for (final uid in widget.assignmentIds!) {
        final doc = await _victimFirestore!.collection('users').doc(uid).get();
        if (!doc.exists) continue;
        final data = doc.data();
        final status = data?['requestAccepted'] ?? 'pending';
        if (status != 'pending') continue;

        pending.add({
          'uid': uid,
          'name': data?['name'] ?? 'N/A',
          'severity': data?['severity'] ?? 'N/A',
          'location': data?['location'] ?? 'N/A',
          'requestAccepted': status,
        });
      }

      if (mounted) {
        ref.read(globalPageProvider.notifier).setVictims(pending);
      }
    } catch (e) {
      rethrow;
    } finally {
      if (mounted) ref.read(globalPageProvider.notifier).setIsLoading(false);
    }
  }

  Future<void> updateRequestStatus(
    String uid,
    String newStatus,
    bool? isAssigned,
  ) async {
    if (_victimFirestore == null) return;

    if (!mounted) return;
    ref.read(globalPageProvider.notifier).setIsLoading(true);

    try {
      await _victimFirestore!.collection('users').doc(uid).set({
        'requestAccepted': newStatus,
      }, SetOptions(merge: true));
      await ngoFirestore!.collection('requests').doc(uid).set({
        'assigned': isAssigned,
      }, SetOptions(merge: true));

      if (isAssigned != null && isAssigned == false) {
        final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserUid != null) {
          final rescuerFirestore = FirebaseFirestore.instance;
          final rescuerDocRef = rescuerFirestore
              .collection('users')
              .doc(currentUserUid);
          final rescuerDoc = await rescuerDocRef.get();

          if (rescuerDoc.exists) {
            final currentRequests = rescuerDoc.data()?['requests'] ?? 0;
            if (currentRequests != 0) {
              await rescuerDocRef.update({
                'requests': FieldValue.increment(-1),
              });
            }
          }
        }
      }

      // Refresh the pending list after update
      await fetchPendingRequests();
    } catch (e) {
      pageMessage(
        'Failed to update status, Please try again',
        context,
        AppColors.error,
      );
      if (mounted) ref.read(globalPageProvider.notifier).setIsLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                      'Requests',
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

    // Check loading state first
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
                Icons.pending_actions,
                color: AppColors.textSecondary.withOpacity(0.5),
                size: ResponsiveHelper.isTablet(context) ? 96 : 64,
              ),
              SizedBox(height: ResponsiveHelper.isTablet(context) ? 24 : 16),
              Text(
                'No requests available',
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
        return _buildRequestCard(victims[index], ref);
      },
    );
  }

  Widget _buildLoadingOverlay(WidgetRef ref) {
    if (!context.mounted) return const SizedBox.shrink();
    final isLoading = ref.watch(globalPageProvider.select((v) => v.isLoading));

    if (!isLoading) return const SizedBox.shrink();
    return pageLoading(context);
  }

  Widget _buildRequestCard(Map<String, dynamic> victim, WidgetRef ref) {
    final name = victim['name'] ?? 'N/A';
    final severity = victim['severity'] ?? 'N/A';
    final location = victim['location'] ?? 'N/A';

    if (!mounted) return const SizedBox.shrink();

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
      ),
      child: Container(
        padding: EdgeInsets.all(ResponsiveHelper.isTablet(context) ? 24 : 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppText.fieldLabel.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkCharcoal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              severity,
                              style: AppText.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              style: AppText.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: ResponsiveHelper.isTablet(context) ? 24 : 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (victim['uid'] != null) {
                        await updateRequestStatus(
                          victim['uid'],
                          'accepted',
                          null,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveHelper.isTablet(context) ? 18 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    label: const Text('Accept'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (victim['uid'] != null) {
                        await updateRequestStatus(
                          victim['uid'],
                          'rejected',
                          false,
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveHelper.isTablet(context) ? 18 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
