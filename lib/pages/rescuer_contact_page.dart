import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'dart:io' show Platform;

import 'package:life_line_rescuer/providers/call_state_provider.dart';
import 'package:life_line_rescuer/providers/incoming_call_provider.dart';
import 'package:life_line_rescuer/providers/rescuer_contact_provider.dart';
import 'package:life_line_rescuer/services/call_service.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/utils/responsive_helper.dart';
import 'package:life_line_rescuer/widgets/global/bottom_navbar.dart';
import 'package:life_line_rescuer/widgets/global/in_out_calls.dart';
import 'package:life_line_rescuer/widgets/global/incoming_call_screen.dart';
import 'package:life_line_rescuer/widgets/global/ngo_chat_screen.dart';
import 'package:life_line_rescuer/widgets/global/page_loading.dart';
import 'package:life_line_rescuer/widgets/global/page_message.dart';
import 'package:life_line_rescuer/widgets/global/page_navigation.dart';
import 'package:life_line_rescuer/widgets/global/rescuer_chat_screen.dart';
import 'package:life_line_rescuer/widgets/global/outgoing_calling_screen.dart';
import 'package:life_line_rescuer/widgets/global/called_feedback_screen.dart';

class RescuerContactPage extends ConsumerStatefulWidget {
  const RescuerContactPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RescuerContactPageState();
}

class _RescuerContactPageState extends ConsumerState<RescuerContactPage> {
  FirebaseFirestore? victimFirestore;
  FirebaseFirestore? ngoFirestore;
  ProviderSubscription? _callStreamSubscription;
  ProviderSubscription? _incomingCallSubscription;

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

  bool _hasJoinedJitsi = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSecondaryFirebase();
      _listenToCallState();
    });
  }

  @override
  void dispose() {
    _callStreamSubscription?.close();
    _incomingCallSubscription?.close();
    super.dispose();
  }

  void _listenToCallState() {
    // 1. Listener for Outgoing Call workflows
    _callStreamSubscription = ref.listenManual<
      AsyncValue<DocumentSnapshot?>
    >(currentCallDocStreamProvider, (previous, next) {
      if (!mounted) return;
      final currentCallId = ref.read(currentCallIdProvider);

      if (currentCallId == null) {
        _hasJoinedJitsi = false;
        return;
      }

      next.whenData((callDoc) {
        if (callDoc != null && callDoc.exists) {
          final callData = callDoc.data() as Map<String, dynamic>?;
          final callStatus = callData?['status'] ?? '';
          final senderId = callData?['senderId'] ?? '';
          final targetName = callData?['callerName'] ?? 'Caller';

          if (callStatus == 'ringing') {
            if (previous?.value == null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  settings: const RouteSettings(name: '/outgoing-call'),
                  builder:
                      (context) => OutgoingCallScreen(
                        callId: currentCallId,
                        receiverName: targetName,
                      ),
                ),
              );
            }
          } else if (callStatus == 'accepted') {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (senderId == currentUserId && !_hasJoinedJitsi) {
              _hasJoinedJitsi = true;
              CallService.joinRoom(
                roomName: currentCallId,
                displayName: callData?['callerName'] ?? 'Unknown',
                avatarUrl: callData?['callerPhotoUrl'] ?? '',
                audioOnly: callData?['audioOnly'] ?? false,
              );
            }
            // Safely remove the outgoing call screen without popping the whole stack
            Navigator.of(
              context,
            ).popUntil((route) => route.settings.name != '/outgoing-call');
          } else if (callStatus == 'declined' || callStatus == 'ended') {
            CallService.hangUp();

            // Remove outgoing calling screen and present feedback
            Navigator.of(
              context,
            ).popUntil((route) => route.settings.name != '/outgoing-call');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => CallFeedbackScreen(
                      title:
                          callStatus == 'declined'
                              ? 'Call Declined'
                              : 'Call Ended',
                      subtitle:
                          callStatus == 'declined'
                              ? 'The recipient has declined your call.'
                              : 'The conversation has ended',
                      icon:
                          callStatus == 'declined'
                              ? Icons.gpp_bad_rounded
                              : Icons.phone_disabled_rounded,
                      iconColor: AppColors.error,
                    ),
              ),
            );
          }
        } else if (callDoc != null && !callDoc.exists) {
          CallService.hangUp();
          ref.read(currentCallIdProvider.notifier).state = null;
          Navigator.of(
            context,
          ).popUntil((route) => route.settings.name != '/outgoing-call');
        }
      });
    });

    // 2. Listener for Incoming Call Stream Provider
    _incomingCallSubscription = ref.listenManual<
      AsyncValue<Map<String, dynamic>?>
    >(incomingCallStreamProvider, (previous, next) {
      if (!mounted) return;

      next.whenData((incomingCallData) {
        if (incomingCallData != null && previous?.value == null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              settings: const RouteSettings(name: '/incoming-call'),
              builder: (context) => const IncomingCallScreen(),
            ),
          );
        } else if (incomingCallData == null && previous?.value != null) {
          // If the call document disappears or clears externally, dismiss the overlay screen automatically
          Navigator.of(
            context,
          ).popUntil((route) => route.settings.name != '/incoming-call');
        }
      });
    });
  }

  Future<void> _initSecondaryFirebase() async {
    if (mounted) {
      ref.read(rescuerContactLoadingProvider.notifier).state = true;
    }
    try {
      FirebaseApp rescuerApp;
      FirebaseApp ngoApp;

      try {
        rescuerApp = Firebase.app('project-life-line');
      } catch (_) {
        rescuerApp = await Firebase.initializeApp(
          name: 'project-life-line',
          options: Platform.isIOS ? _victimIosOptions : _victimAndroidOptions,
        );
      }

      victimFirestore = FirebaseFirestore.instanceFor(app: rescuerApp);

      try {
        ngoApp = Firebase.app('life-line-ngo');
      } catch (_) {
        ngoApp = await Firebase.initializeApp(
          name: 'life-line-ngo',
          options: _ngoFirebaseOptions,
        );
      }

      ngoFirestore = FirebaseFirestore.instanceFor(app: ngoApp);

      await _fetchAssignedVictims();
      await _fetchAssignedNgo();

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
        pageNavigation(const InOutCalls(child: LandingPage()), context);
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

  Future<void> _fetchAssignedNgo() async {
    if (ngoFirestore == null) return;

    try {
      final rescuerId = FirebaseAuth.instance.currentUser?.uid;
      if (rescuerId == null) return;

      final rescuerDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(rescuerId)
              .get();

      if (!rescuerDoc.exists) return;

      final ngoId = rescuerDoc.data()?['ngoId'];
      if (ngoId == null || ngoId.toString().isEmpty) return;

      final ngoDoc =
          await ngoFirestore!.collection('ngo-info-database').doc(ngoId).get();

      if (!ngoDoc.exists) return;

      final data = ngoDoc.data()!;

      if (mounted) {
        ref.read(assignedNgoProvider.notifier).state = {
          'id': ngoId,
          'ngoName': data['ngoName'] ?? 'Unknown NGO',
          'geographicalCoverage': data['geographicalCoverage'] ?? 'N/A',
        };
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
    final ngo = ref.watch(assignedNgoProvider);

    if (isLoading) {
      return pageLoading(context);
    }

    if (victims.isEmpty && ngo == null) {
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
                'No contacts assigned yet',
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

    return ListView(
      padding: EdgeInsets.all(ResponsiveHelper.isTablet(context) ? 32 : 16),
      children: [
        ...victims.map((victim) => _buildVictimCard(victim)),
        if (ngo != null) _buildNgoCard(ngo),
      ],
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
      child: ListTile(
        onTap: () {
          pageNavigation(
            InOutCalls(
              child: RescuerChatScreen(
                victimId: victim['id'] ?? '',
                victimName: name,
                photoUrl: photoURL,
              ),
            ),
            context,
          );
        },
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
                    border: Border.all(color: AppColors.surfaceLight, width: 2),
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
          onPressed: () async {
            final rescuerId = FirebaseAuth.instance.currentUser?.uid;
            if (rescuerId == null) return;

            await CallService.initiateCall(
              callerId: rescuerId,
              receiverId: victim['id'] ?? '',
              callerName: 'Rescuer',
              callerPhotoUrl: FirebaseAuth.instance.currentUser?.photoURL ?? '',
              ref: ref,
              audioOnly: false,
            );
          },
        ),
      ),
    );
  }

  Widget _buildNgoCard(Map<String, dynamic> ngo) {
    final ngoName = ngo['ngoName'] ?? 'Unknown NGO';
    final geographicalCoverage = ngo['geographicalCoverage'] ?? 'N/A';

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
      child: ListTile(
        mouseCursor: SystemMouseCursors.click,
        onTap: () {
          pageNavigation(
            InOutCalls(
              child: NgoChatScreen(ngoId: ngo['id'] ?? '', ngoName: ngoName),
            ),
            context,
          );
        },
        contentPadding: EdgeInsets.all(
          ResponsiveHelper.isTablet(context) ? 24 : 16,
        ),
        leading: _buildNgoLogo(ngoName),
        title: Text(
          ngoName,
          style: AppText.fieldLabel.copyWith(
            fontSize: ResponsiveHelper.isTablet(context) ? 20 : 16,
            fontWeight: FontWeight.w700,
            color: AppColors.darkCharcoal,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            geographicalCoverage,
            style: AppText.small.copyWith(
              color: AppColors.textSecondary,
              fontSize: ResponsiveHelper.bodyFont(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNgoLogo(String ngoName) {
    return Container(
      width: ResponsiveHelper.isTablet(context) ? 72 : 48,
      height: ResponsiveHelper.isTablet(context) ? 72 : 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/offline_logos/$ngoName.webp',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.primaryMaroon.withOpacity(0.1),
              child: Icon(
                Icons.business,
                color: AppColors.primaryMaroon,
                size: ResponsiveHelper.isTablet(context) ? 36 : 24,
              ),
            );
          },
        ),
      ),
    );
  }
}
