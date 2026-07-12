import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:life_line_rescuer/pages/rescuer_onboarding.dart';
import 'package:life_line_rescuer/providers/landing_page_provider.dart';
import 'package:life_line_rescuer/services/appwrite_service.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/utils/responsive_helper.dart';
import 'package:life_line_rescuer/widgets/global/bottom_navbar.dart';
import 'package:life_line_rescuer/pages/service_cards/missions_card_sheet.dart';
import 'package:life_line_rescuer/pages/service_cards/requests_card_sheet.dart';
import 'package:life_line_rescuer/widgets/global/page_loading.dart';
import 'package:life_line_rescuer/widgets/global/page_message.dart';
import 'package:life_line_rescuer/widgets/global/page_navigation.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
    });
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;

    // Set loading state to true
    ref.read(landingPageProvider.notifier).setIsLoading(true);

    try {
      // Get current user from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          ref.read(landingPageProvider.notifier).setIsLoading(false);
        }
        return;
      }

      final userUid = user.uid;

      // Fetch user data from Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userUid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          final requests = userData['requests'] ?? 0;

          final assigned =
              (userData['assigned'] as Map<String, dynamic>?) ?? {};

          final assignmentCount = assigned.length;
          final assignmentIds = assigned.keys.toList(); // List<String>

          int highPriority = 0;

          for (final entry in assigned.entries) {
            if (entry.value == 'High Risk') {
              highPriority++;
            }
          }

          if (mounted) {
            ref.read(landingPageProvider.notifier).setActiveRequests({
              'activeRequests': requests,
              'highPriority': highPriority,
              'assignments': assignmentCount, // int, for the stat card
              'assignmentIds':
                  assignmentIds, // List<String>, for the bottom sheet
            });
          }
        }
      }

      if (mounted) {
        ref.read(landingPageProvider.notifier).setIsLoading(false);
      }
    } catch (e) {
      if (mounted) {
        ref.read(landingPageProvider.notifier).setIsLoading(false);
        pageMessage(
          'Failed to load user data. Please try again.',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
      }

      pageNavigation(const RescuerOnboarding(), context);
    } catch (e) {
      if (context.mounted) {
        pageMessage(
          'Failed to logout. Please try again.',
          context,
          AppColors.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        centerTitle: true,
        title: const Text('LifeLine', style: AppText.appHeader),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () async {
              await _handleLogout(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: ResponsiveHelper.contentWidth(context),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.horizontalPadding(context),
                      vertical: ResponsiveHelper.verticalPadding(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            return _buildStatisticsSection(ref);
                          },
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        _buildQuickActions(),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
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
      bottomNavigationBar: const BottomNavbar(currentIndex: 0),
    );
  }

  Widget _buildLoadingOverlay(WidgetRef ref) {
    if (!context.mounted) return const SizedBox.shrink();
    final isLoading = ref.watch(landingPageProvider.select((v) => v.isLoading));

    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return pageLoading(context);
  }

  Widget _buildStatisticsSection(WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final dashboardData = ref.watch(
      landingPageProvider.select((v) => v.activeRequests),
    );

    final activeRequests = dashboardData['activeRequests'] ?? 0;
    final highPriority = dashboardData['highPriority'] ?? 0;
    final assignments = dashboardData['assignments'] ?? 0;

    // Only show stats if there's actual data
    final hasData = activeRequests > 0 || highPriority > 0 || assignments > 0;

    if (!hasData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No active missions yet',
              style: AppText.fieldLabel.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You\'ll see your statistics here once you start',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _StatCard(title: 'Active Requests', value: activeRequests.toString()),
        const SizedBox(height: 12),
        _StatCard(title: 'High Priority', value: highPriority.toString()),
        const SizedBox(height: 12),
        _StatCard(title: 'Assignments', value: assignments.toString()),
      ],
    );
  }

  Widget _buildQuickActions() {
    // Only functional actions with actual implementations
    final actions = [
      {'title': 'Missions', 'icon': Icons.assignment_turned_in},
      {'title': 'Requests', 'icon': Icons.pending_actions},
      {'title': 'Guide', 'icon': Icons.menu_book},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: AppText.fieldLabel),
        const SizedBox(height: AppSpacing.lg),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final dashboardRequests =
                      ref.read(landingPageProvider).activeRequests;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      if (action['title'] == 'Guide') {
                        try {
                          if (mounted) {
                            ref
                                .read(landingPageProvider.notifier)
                                .setIsLoading(true);
                          }
                          await AppwriteService.downloadGuide();

                          if (mounted) {
                            ref
                                .read(landingPageProvider.notifier)
                                .setIsLoading(false);
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ref
                              .read(landingPageProvider.notifier)
                              .setIsLoading(false);
                          pageMessage(
                            'Failed to download the file, please retry',
                            context,
                            AppColors.error,
                          );
                        }
                      } else if (action['title'] == 'Missions') {
                        if (mounted) {
                          MissionsCardSheet.show(
                            context,
                            assignments: dashboardRequests['assignmentIds'],
                          );
                        }
                      } else if (action['title'] == 'Requests') {
                        if (mounted) {
                          final active =
                              dashboardRequests['activeRequests'] ?? 0;
                          final ids =
                              (dashboardRequests['assignmentIds']
                                      as List<dynamic>?)
                                  ?.cast<String>() ??
                              [];
                          RequestsCardSheet.show(
                            context,
                            activeRequests: active,
                            assignmentIds: ids,
                          );
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          action['icon'] as IconData,
                          size: 30,
                          color: AppColors.primaryMaroon,
                        ),
                        const SizedBox(height: 8),
                        Text(action['title'] as String, style: AppText.small),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppText.fieldLabel.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: AppText.formTitle.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryMaroon,
            ),
          ),
        ],
      ),
    );
  }
}
