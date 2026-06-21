import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/providers/global_sheet_provider.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/utils/responsive_helper.dart';
import 'package:life_line_rescuer/widgets/global/page_loading.dart';

class GlobalBottomSheet {
  static void show(BuildContext context, {List<String>? assignments}) {
    showModalBottomSheet(
      isDismissible: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlobalSheet(assigned: assignments),
    );
  }
}

class GlobalSheet extends ConsumerStatefulWidget {
  final List<String>? assigned;
  const GlobalSheet({super.key, this.assigned});

  @override
  ConsumerState<GlobalSheet> createState() => _GlobalSheetState();
}

class _GlobalSheetState extends ConsumerState<GlobalSheet> {
  FirebaseFirestore? _victimFirestore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSecondaryFirebase();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initSecondaryFirebase() async {
    try {
      ref.read(globalPageProvider.notifier).setIsLoading(true);

      _victimFirestore = FirebaseFirestore.instanceFor(
        app: Firebase.app('life-line-victim'),
      );

      await _fetchVictimData();

      ref.read(globalPageProvider.notifier).setIsLoading(false);
    } catch (e) {
      ref.read(globalPageProvider.notifier).setIsLoading(false);
    }
  }

  Future<void> _fetchVictimData() async {
    if (_victimFirestore == null || widget.assigned == null) return;

    try {
      final List<Map<String, dynamic>> victims = [];

      for (final uid in widget.assigned!) {
        final docSnapshot =
            await _victimFirestore!.collection('users').doc(uid).get();
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          victims.add({
            'uid': uid,
            'name': data?['name'] ?? 'Unknown',
            'severity': data?['severity'] ?? 'Unknown',
            'riskLevel': data?['riskLevel'] ?? 'Low',
            'location': data?['location'] ?? 'Unknown',
          });
        }
      }

      if (mounted) {
        ref.read(globalPageProvider.notifier).setVictims(victims);
      }
    } catch (e) {
      rethrow;
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRiskEmoji(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
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
          _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBody(WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
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
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isTablet(context) ? 32 : 16,
      ),
      itemCount: victims.length,
      itemBuilder: (context, index) {
        return _buildMissionCard(victims[index]);
      },
    );
  }

  Widget _buildLoadingOverlay() {
    if (!context.mounted) return const SizedBox.shrink();
    final isLoading = ref.watch(globalPageProvider.select((v) => v.isLoading));

    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return pageLoading(context);
  }

  Widget _buildMissionCard(Map<String, dynamic> victim) {
    final name = victim['name'] ?? 'Unknown';
    final emergencyType = victim['emergencyType'] ?? 'Unknown';
    final riskLevel = victim['riskLevel'] ?? 'Low';
    final riskColor = _getRiskColor(riskLevel);
    final riskEmoji = _getRiskEmoji(riskLevel);

    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.isTablet(context) ? 24 : 16,
        top: ResponsiveHelper.isTablet(context) ? 24 : 16,
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
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.isTablet(context) ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Victim Name with Risk Indicator
            Row(
              children: [
                Text(
                  riskEmoji,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.isTablet(context) ? 24 : 20,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.isTablet(context) ? 12 : 8),
                Expanded(
                  child: Text(
                    name,
                    style: AppText.fieldLabel.copyWith(
                      fontSize: ResponsiveHelper.isTablet(context) ? 20 : 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.isTablet(context) ? 12 : 8),
            // Emergency Type
            Text(
              emergencyType,
              style: AppText.small.copyWith(
                color: AppColors.textSecondary,
                fontSize: ResponsiveHelper.bodyFont(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: ResponsiveHelper.isTablet(context) ? 8 : 6),
            // Risk Level
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.isTablet(context) ? 12 : 8,
                    vertical: ResponsiveHelper.isTablet(context) ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: riskColor, width: 1),
                  ),
                  child: Text(
                    '$riskLevel Risk',
                    style: AppText.small.copyWith(
                      color: riskColor,
                      fontSize: ResponsiveHelper.isTablet(context) ? 14 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.isTablet(context) ? 16 : 12),
            // Open Details Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.isTablet(context) ? 14 : 12,
                  ),
                  side: const BorderSide(
                    color: AppColors.primaryMaroon,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Open Details',
                  style: AppText.button.copyWith(
                    fontSize: ResponsiveHelper.bodyFont(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
