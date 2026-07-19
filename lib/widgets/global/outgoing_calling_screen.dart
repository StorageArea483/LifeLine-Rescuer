import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/providers/call_state_provider.dart';
import 'package:life_line_rescuer/services/call_service.dart';
import 'package:life_line_rescuer/styles/styles.dart';

class OutgoingCallScreen extends ConsumerWidget {
  final String callId;
  final String receiverName;

  const OutgoingCallScreen({
    super.key,
    required this.callId,
    required this.receiverName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.primaryMaroon,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Avatar
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // Receiver Name
                Text(
                  receiverName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                // Call Status
                const Text(
                  "Calling...",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    letterSpacing: 0.4,
                  ),
                ),

                const Spacer(),

                // End Call Button
                GestureDetector(
                  onTap: () async {
                    await CallService.cancelCall(callId);
                    if (!context.mounted) return;
                    ref.read(currentCallIdProvider.notifier).state = null;
                  },
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
