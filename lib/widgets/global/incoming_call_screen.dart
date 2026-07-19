import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/providers/incoming_call_provider.dart';
import 'package:life_line_rescuer/services/call_service.dart';
import 'package:life_line_rescuer/styles/styles.dart';

class IncomingCallScreen extends ConsumerWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callAsync = ref.watch(incomingCallStreamProvider);

    return callAsync.when(
      loading:
          () => const Scaffold(
            backgroundColor: AppColors.softBackground,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryMaroon),
            ),
          ),
      error:
          (_, _) => const Scaffold(
            backgroundColor: AppColors.softBackground,
            body: Center(
              child: Text(
                "Error fetching call info",
                style: TextStyle(color: AppColors.primaryMaroon),
              ),
            ),
          ),
      data: (call) {
        if (call == null) {
          return const Scaffold(
            backgroundColor: AppColors.softBackground,
            body: SizedBox.shrink(),
          );
        }

        final callId = call['callId'] as String;
        final callerName = call['callerName'] ?? 'Unknown';
        final callerPhotoUrl = call['callerPhotoUrl'] ?? '';
        final audioOnly = call['audioOnly'] ?? false;

        return Scaffold(
          backgroundColor: AppColors.primaryMaroon,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Text(
                    audioOnly ? 'Incoming Voice Call' : 'Incoming Video Call',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    backgroundImage:
                        callerPhotoUrl.isNotEmpty
                            ? NetworkImage(callerPhotoUrl)
                            : null,
                    child:
                        callerPhotoUrl.isEmpty
                            ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 56,
                            )
                            : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Decline Button Action
                      _callActionButton(
                        icon: Icons.call_end_rounded,
                        color: Colors.red,
                        label: 'Decline',
                        onTap: () async {
                          await CallService.declineCall(callId);
                          if (context.mounted) {
                            Navigator.of(
                              context,
                            ).pop(); // Navigates cleanly back to underlying screen
                          }
                        },
                      ),

                      // Accept Button Action
                      _callActionButton(
                        icon: Icons.call_rounded,
                        color: Colors.green,
                        label: 'Accept',
                        onTap: () async {
                          if (!context.mounted) return;
                          ref.read(activeCallIdProvider.notifier).state =
                              callId;

                          // Navigates cleanly back to underlying screen
                          if (context.mounted) Navigator.of(context).pop();

                          await CallService.acceptCall(
                            callId: callId,
                            displayName: callerName,
                            avatarUrl: callerPhotoUrl,
                            audioOnly: audioOnly,
                          );

                          // Reset state after communication engine has spawned successfully
                          if (!context.mounted) return;
                          ref.read(activeCallIdProvider.notifier).state = null;
                        },
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _callActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 32,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}
