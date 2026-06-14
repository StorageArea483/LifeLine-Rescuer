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
      color: Colors.black54,
      child: Center(
        child: Material(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 32, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'No Internet',
                  style: AppText.subtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: TextButton(
                    onPressed: () {
                      ref.invalidate(internetProvider);
                    },
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
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
