import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:life_line_rescuer/providers/profile_page_provider.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/utils/responsive_helper.dart';
import 'package:life_line_rescuer/widgets/global/bottom_navbar.dart';
import 'package:life_line_rescuer/widgets/global/page_message.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override  
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Set loading to true
    Future(() {
      if (mounted) {
        ref.read(profileLoadingProvider.notifier).state = true;
      }
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user data from Firestore
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data();
        if (mounted) {
          Future(() {
            ref.read(userDataProvider.notifier).state = userData;
          });
        }
      } else {
        // Create a basic user document if it doesn't exist
        final basicData = {
          'email': user.email ?? 'N/A',
          'firstName': 'N/A',
          'lastName': 'N/A',
          'branchName': 'N/A',
          'latitude': 0.0,
          'longitude': 0.0,
          'location': 'N/A',
          'ngoName': 'N/A',
          'phone': 'N/A',
          'selectedService': 'N/A',
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(basicData);

        if (mounted) {
          Future(() {
            ref.read(userDataProvider.notifier).state = basicData;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        pageMessage('Failed to load profile data', context, AppColors.error);
      }
    } finally {
      Future(() {
        if (mounted) {
          ref.read(profileLoadingProvider.notifier).state = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(profileLoadingProvider);
    final userData = ref.watch(userDataProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.softBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: AppText.appHeader.copyWith(
            fontSize: ResponsiveHelper.isTablet(context) ? 24 : 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child:
            isLoading
                ? _buildLoadingOverlay()
                : SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: ResponsiveHelper.contentWidth(context),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.horizontalPadding(
                            context,
                          ),
                          vertical: ResponsiveHelper.verticalPadding(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height:
                                  ResponsiveHelper.isTablet(context) ? 32 : 24,
                            ),
                            // Profile Header with Avatar
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width:
                                        ResponsiveHelper.isTablet(context)
                                            ? 120
                                            : 100,
                                    height:
                                        ResponsiveHelper.isTablet(context)
                                            ? 120
                                            : 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryMaroon
                                          .withOpacity(0.1),
                                      border: Border.all(
                                        color: AppColors.primaryMaroon,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryMaroon
                                              .withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child:
                                          user?.photoURL != null
                                              ? Image.network(
                                                user!.photoURL!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Icon(
                                                    Icons.person,
                                                    size:
                                                        ResponsiveHelper.isTablet(
                                                              context,
                                                            )
                                                            ? 60
                                                            : 50,
                                                    color:
                                                        AppColors.primaryMaroon,
                                                  );
                                                },
                                              )
                                              : Icon(
                                                Icons.person,
                                                size:
                                                    ResponsiveHelper.isTablet(
                                                          context,
                                                        )
                                                        ? 60
                                                        : 50,
                                                color: AppColors.primaryMaroon,
                                              ),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        ResponsiveHelper.isTablet(context)
                                            ? 24
                                            : 16,
                                  ),
                                  Text(
                                    '${userData?['firstName'] ?? 'N/A'} ${userData?['lastName'] ?? ''}',
                                    style: AppText.formTitle.copyWith(
                                      fontSize: ResponsiveHelper.titleFont(
                                        context,
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height:
                                  ResponsiveHelper.isTablet(context) ? 24 : 16,
                            ),
                            // Information Card
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(
                                ResponsiveHelper.isTablet(context) ? 32 : 24,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.borderColor,
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadowLight,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    'Branch Name',
                                    userData?['branchName'] ?? 'N/A',
                                    Icons.business_outlined,
                                  ),
                                  _buildDivider(),
                                  _buildInfoRow(
                                    'Email',
                                    userData?['email'] ?? user?.email ?? 'N/A',
                                    Icons.email_outlined,
                                  ),
                                  _buildDivider(),
                                  _buildInfoRow(
                                    'First Name',
                                    userData?['firstName'] ?? 'N/A',
                                    Icons.person_outline,
                                  ),
                                  _buildDivider(),
                                  _buildInfoRow(
                                    'Last Name',
                                    userData?['lastName'] ?? 'N/A',
                                    Icons.person_outline,
                                  ),
                                  _buildDivider(),
                                  _buildInfoRow(
                                    'Latitude',
                                    _formatCoordinate(userData?['latitude']),
                                    Icons.pin_drop_outlined,
                                  ),
                                  _buildDivider(),
                                  _buildInfoRow(
                                    'Longitude',
                                    _formatCoordinate(userData?['longitude']),
                                    Icons.pin_drop_outlined,
                                  ),
                                  _buildDivider(),
                                  _buildInfoRow(
                                    'Location',
                                    userData?['location'] ?? 'N/A',
                                    Icons.location_on_outlined,
                                  ),
                                  _buildDivider(),
                                  _buildInfoRow(
                                    'Registered With',
                                    userData?['ngoName'] ?? 'N/A',
                                    Icons.local_hospital_outlined,
                                  ),
                                  _buildDivider(),
                                  _buildInfoRow(
                                    'Phone',
                                    userData?['phone'] ?? 'N/A',
                                    Icons.phone_outlined,
                                  ),
                                  _buildDivider(),
                                  _buildInfoRow(
                                    'Serving Type',
                                    userData?['selectedService'] ?? 'N/A',
                                    Icons.medical_services_outlined,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height:
                                  ResponsiveHelper.isTablet(context) ? 48 : 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      ),
      bottomNavigationBar: const BottomNavbar(currentIndex: 3),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      decoration: AppContainers.pageContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryMaroon),
            SizedBox(height: ResponsiveHelper.isTablet(context) ? 24 : 16),
            Text(
              'Loading profile...',
              style: AppText.small.copyWith(
                color: AppColors.textSecondary,
                fontSize: ResponsiveHelper.bodyFont(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.isTablet(context) ? 16 : 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: ResponsiveHelper.isTablet(context) ? 28 : 22,
            color: AppColors.primaryMaroon,
          ),
          SizedBox(width: ResponsiveHelper.isTablet(context) ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.small.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: ResponsiveHelper.isTablet(context) ? 14 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppText.fieldLabel.copyWith(
                    fontSize: ResponsiveHelper.bodyFont(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.borderColor.withOpacity(0.5),
      thickness: 1,
      height: 1,
    );
  }

  String _formatCoordinate(dynamic coordinate) {
    if (coordinate == null) return 'N/A';
    if (coordinate is num) {
      return coordinate.toStringAsFixed(6);
    }
    return coordinate.toString();
  }
}
