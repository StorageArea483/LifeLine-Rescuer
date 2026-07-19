import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/providers/call_state_provider.dart';
import 'package:life_line_rescuer/providers/incoming_call_provider.dart';
import 'package:life_line_rescuer/services/call_service.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/widgets/global/called_feedback_screen.dart';
import 'package:life_line_rescuer/widgets/global/incoming_call_screen.dart';
import 'package:life_line_rescuer/widgets/global/outgoing_calling_screen.dart';

class InOutCalls extends ConsumerStatefulWidget {
  final Widget child;
  const InOutCalls({super.key, required this.child});

  @override
  ConsumerState<InOutCalls> createState() => _InOutCallsState();
}

class _InOutCallsState extends ConsumerState<InOutCalls> {
  ProviderSubscription? _outgoingCallSubscription;
  ProviderSubscription? _incomingCallSubscription;

  bool _hasJoinedJitsi = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToCallState();
    });
  }

  @override
  void dispose() {
    _outgoingCallSubscription?.close();
    _incomingCallSubscription?.close();
    super.dispose();
  }

  void _listenToCallState() {
    // 1. Listener for Outgoing Call workflows
    _outgoingCallSubscription = ref.listenManual<
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
          if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
