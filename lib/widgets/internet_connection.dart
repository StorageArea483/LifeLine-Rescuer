import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/providers/internet_provider.dart';
import 'package:life_line_rescuer/styles/styles.dart';

class InternetConnection extends ConsumerWidget {
  final Widget child;

  const InternetConnection({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!context.mounted) return const SizedBox.shrink();
    final connectionState = ref.watch(internetProvider);

    return connectionState.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      data: (connectivityResult) {
        final hasInternet =
            !connectivityResult.contains(ConnectivityResult.none);

        if (hasInternet) {
          return child;
        } else {
          return Stack(children: [child, const NoInternetOverlay()]);
        }
      },
      loading: () => child,
      error: (_, _) => Stack(children: [child, const NoInternetOverlay()]),
    );
  }
}

class NoInternetOverlay extends ConsumerWidget {
  const NoInternetOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.black.withOpacity(0.65),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 82,
                  width: 82,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.red,
                    size: 42,
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  "No Internet Connection",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Please check your Wi-Fi or mobile data connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(internetProvider);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      "Try Again",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMaroon,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
