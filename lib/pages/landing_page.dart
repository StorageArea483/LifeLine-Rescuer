import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/providers/landing_page_provider.dart';
import 'package:life_line_rescuer/services/appwrite_service.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/utils/responsive_helper.dart';
import 'package:life_line_rescuer/widgets/global/bottom_navbar.dart';
import 'package:life_line_rescuer/widgets/global/page_message.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  int currentIndex = 0;

  final List<Map<String, dynamic>> recentRequests = [
    {"name": "Ahmed Khan", "type": "Medical Emergency", "severity": "HIGH"},
    {"name": "Fatima Ali", "type": "Flood Rescue", "severity": "MEDIUM"},
    {"name": "Bilal Ahmed", "type": "Earthquake", "severity": "CRITICAL"},
  ];

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
              Icons.notifications_active_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: () {},
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
                        _buildStatisticsSection(),
                        const SizedBox(height: AppSpacing.xxl),

                        _buildQuickActions(),
                        const SizedBox(height: AppSpacing.xxl),

                        _buildRecentRequests(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: const BottomNavbar(currentIndex: 0),
    );
  }

  Widget _buildLoadingOverlay() {
    if (!context.mounted) return const SizedBox.shrink();
    final isLoading = ref.watch(landingPageProvider);

    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      color: AppColors.softBackground,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMaroon),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: const [
        _StatCard(title: 'Active Requests', value: '12'),
        _StatCard(title: 'High Priority', value: '4'),
        _StatCard(title: 'Rescued Today', value: '8'),
        _StatCard(title: 'Assignments', value: '3'),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'title': 'Missions', 'icon': Icons.assignment_turned_in},
      {'title': 'Requests', 'icon': Icons.pending_actions},
      {'title': 'History', 'icon': Icons.history},
      {'title': 'Guide', 'icon': Icons.menu_book},
      {'title': 'Success', 'icon': Icons.reviews},
      {'title': 'Reports', 'icon': Icons.summarize},
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
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  if (action['title'] == 'Guide') {
                    try {
                      if (mounted) {
                        ref.read(landingPageProvider.notifier).state = true;
                      }
                      await AppwriteService.downloadGuide();

                      pageMessage(
                        'Psychological First Aid Guidelines downloaded successfully',
                        context,
                        AppColors.success,
                      );
                      if (mounted) {
                        ref.read(landingPageProvider.notifier).state = false;
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ref.read(landingPageProvider.notifier).state = false;
                      pageMessage(e.toString(), context, AppColors.error);
                    }
                    return;
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
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Emergency Requests', style: AppText.fieldLabel),
        const SizedBox(height: AppSpacing.lg),

        ...recentRequests.map(
          (request) => Container(
            margin: const EdgeInsets.only(bottom: 12),
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
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primaryMaroon,
                  child: Icon(Icons.person, color: AppColors.surfaceLight),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request['name'], style: AppText.fieldLabel),
                      Text(
                        request['type'],
                        style: AppText.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
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
                  child: Text(
                    request['severity'],
                    style: AppText.small.copyWith(
                      color: AppColors.primaryMaroon,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.all(12),
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppText.formTitle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(title, textAlign: TextAlign.center, style: AppText.small),
          ],
        ),
      ),
    );
  }
}
