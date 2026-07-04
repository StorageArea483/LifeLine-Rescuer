import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/pages/landing_page.dart';
import 'package:life_line_rescuer/services/auth_service.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/providers/rescuer_onboarding_provider.dart';
import 'package:life_line_rescuer/widgets/global/page_loading.dart';
import 'package:life_line_rescuer/widgets/global/page_message.dart';
import 'package:life_line_rescuer/widgets/global/page_navigation.dart';
import 'package:life_line_rescuer/widgets/google_authentication.dart';

class RescuerOnboarding extends ConsumerStatefulWidget {
  const RescuerOnboarding({super.key});

  @override
  ConsumerState<RescuerOnboarding> createState() => _RescuerOnboardingState();
}

class _RescuerOnboardingState extends ConsumerState<RescuerOnboarding> {
  FirebaseFirestore? _ngoFirestore;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSecondaryFirebase();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initSecondaryFirebase() async {
    if (mounted) {
      ref.read(rescueOnboardingProvider.notifier).setLoading(true);
    }

    try {
      FirebaseApp ngoApp;
      try {
        ngoApp = Firebase.app('life-line-ngo');
      } catch (_) {
        rethrow;
      }

      _ngoFirestore = FirebaseFirestore.instanceFor(app: ngoApp);

      await _checkPendingRequest();

      if (mounted) {
        ref.read(rescueOnboardingProvider.notifier).setLoading(false);
      }
    } catch (e) {
      if (mounted) {
        ref.read(rescueOnboardingProvider.notifier).setLoading(false);

        pageMessage(
          'An unexpected error occurred, Please retry',
          context,
          AppColors.error,
        );
      }
    }
  }

  Future<void> _fetchNgosByService(String service) async {
    if (_ngoFirestore == null) return;

    if (mounted) {
      ref.read(rescueOnboardingProvider.notifier).setIsNgoLoading(true);
      // Clear previous results so stale data does not show.
      ref.read(rescueOnboardingProvider.notifier).setApprovedNgos([]);
    }

    try {
      final snapshot =
          await _ngoFirestore!
              .collection('ngo-info-database')
              .where('approved', isEqualTo: true)
              .where('selectedProgram', isEqualTo: service)
              .get();

      final ngos =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'docId': doc.id,
              'ngoName': data['ngoName'] ?? 'Unknown NGO',
              'selectedProgram': data['selectedProgram'] ?? 'N/A',
              'branchName': data['branchName'] ?? 'N/A',
            };
          }).toList();

      if (mounted) {
        ref.read(rescueOnboardingProvider.notifier).setApprovedNgos(ngos);
        ref.read(rescueOnboardingProvider.notifier).setIsNgoLoading(false);
      }
    } catch (e) {
      if (mounted) {
        ref.read(rescueOnboardingProvider.notifier).setIsNgoLoading(false);
      }
      pageMessage(
        'An unexpected error occurred, Please retry',
        context,
        AppColors.error,
      );
      pageNavigation(const LandingPage(), context);
    }
  }

  void _onServiceSelected(String service) {
    if (!mounted) return;
    ref.read(rescueOnboardingProvider.notifier).setSelectedService(service);
    _fetchNgosByService(service);
  }

  Future<void> _checkPendingRequest() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!doc.exists) return;

      final data = doc.data();

      if (data == null) return;

      if (data['status'] == 'pending' && mounted) {
        _showPendingDialog(false);
      }
      if (data['status'] == 'rejected' && mounted) {
        _showPendingDialog(true);
      }
    } catch (_) {
      rethrow;
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    // Regex: only alphabets (A-Z, a-z) and spaces
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Only alphabets are allowed';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Pakistani phone number validation: starts with 03 and has 11 digits
    final phoneRegex = RegExp(r'^03[0-9]{9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid Pakistani number';
    }
    return null;
  }

  void _showPendingDialog(bool rejected) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppColors.softBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.xxl),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryMaroon.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rejected ? Icons.close : Icons.hourglass_top,
                    color: rejected ? Colors.red : AppColors.primaryMaroon,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rejected
                          ? 'Your request has been rejected.'
                          : 'Please wait while NGO accepts your request.',
                      textAlign: TextAlign.center,
                      style: AppText.fieldLabel.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    if (rejected)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            await GoogleSignInService.signOut();
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Logout'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit(String selectedNgoId) async {
    if (!mounted) return;
    ref.read(rescueOnboardingProvider.notifier).setIsSubmitting(true);
    if (!mounted) return;
    final selectedService = ref.read(rescueOnboardingProvider).selectedService;
    if (selectedService == null) {
      if (mounted) {
        ref.read(rescueOnboardingProvider.notifier).setIsSubmitting(false);
        pageMessage(
          'Please select a service in order to continue.',
          context,
          AppColors.error,
        );
      }
      return;
    }

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (mounted) {
          ref.read(rescueOnboardingProvider.notifier).setIsSubmitting(false);
          pageMessage('Failed to authenticate user.', context, AppColors.error);
        }
        return;
      }

      final userUid = currentUser.uid;
      final existingDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userUid)
              .get();

      if (existingDoc.exists) {
        final status = existingDoc.data()?['status'];

        if (status == 'pending') {
          if (mounted) {
            _showPendingDialog(false);
          }
          return;
        }
        if (status == 'rejected') {
          if (mounted) {
            _showPendingDialog(true);
          }
          return;
        }
      }
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final phone = _phoneController.text.trim();

      // Get the selected NGO details
      if (!mounted) return;
      final approvedNgos = ref.read(
        rescueOnboardingProvider.select((v) => v.approvedNgos),
      );
      final selectedNgo = approvedNgos.firstWhere(
        (ngo) => ngo['docId'] == selectedNgoId,
        orElse: () => {},
      );

      final ngoName = selectedNgo['ngoName'] ?? 'Unknown NGO';
      final branchName = selectedNgo['branchName'] ?? 'N/A';

      // Store user data in life-line-rescuer database (users collection)
      final rescuerFirestore = FirebaseFirestore.instance;
      await rescuerFirestore.collection('users').doc(userUid).set({
        'id': userUid,
        'ngoId': selectedNgoId,
        'selectedService': selectedService,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'ngoName': ngoName,
        'branchName': branchName,
        'status': 'pending',
        'blocked': false,
        'online': true,
        'requests': 0,
      }, SetOptions(merge: true));

      // Store request in life-line-ngo database under selected NGO's requests subcollection
      if (_ngoFirestore != null) {
        await _ngoFirestore!
            .collection('ngo-info-database')
            .doc(selectedNgoId)
            .collection('rescuer-requests')
            .doc(userUid)
            .set({
              'id': userUid,
              'ngoId': selectedNgoId,
              'selectedService': selectedService,
              'firstName': firstName,
              'lastName': lastName,
              'phone': phone,
              'ngoName': ngoName,
              'branchName': branchName,
              'status': 'pending',
              'blocked': false,
              'online': true,
              'requests': 0,
            }, SetOptions(merge: true));
      }

      if (mounted) {
        ref.read(rescueOnboardingProvider.notifier).setIsSubmitting(false);
        _showPendingDialog(false);
      }
    } catch (e) {
      if (mounted) {
        ref.read(rescueOnboardingProvider.notifier).setIsSubmitting(false);
        pageMessage(
          'Failed to send request. Please try again.',
          context,
          AppColors.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: AppContainers.pageContainer,
            child: SafeArea(
              child: Consumer(
                builder: (context, ref, child) {
                  return _buildBody(ref);
                },
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
    final isLoading = ref.watch(
      rescueOnboardingProvider.select((v) => v.isLoading),
    );

    if (isLoading) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLogo(),
          const SizedBox(height: AppSpacing.sm),
          _buildTitle(),
          const SizedBox(height: AppSpacing.xxl),
          _buildForm(),
          const SizedBox(height: AppSpacing.lg),
          // Terms Footer
          RichText(
            textAlign: TextAlign.center,

            text: TextSpan(
              style: AppText.footer.copyWith(color: AppColors.textLight),

              children: [
                const TextSpan(text: 'By continuing, you agree to our '),

                WidgetSpan(
                  child: GestureDetector(
                    onTap:
                        () => showPolicyDialog(
                          context,

                          'Terms of Service',

                          termsOfService,
                        ),

                    child: Text(
                      'Terms of Service',

                      style: AppText.footerLink.copyWith(
                        color: AppColors.primaryMaroon,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const TextSpan(text: ' and '),

                WidgetSpan(
                  child: GestureDetector(
                    onTap:
                        () => showPolicyDialog(
                          context,

                          'Privacy Policy',

                          privacyPolicy,
                        ),

                    child: Text(
                      'Privacy Policy',

                      style: AppText.footerLink.copyWith(
                        color: AppColors.primaryMaroon,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showPolicyDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,

      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),

            child: Container(
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: AppColors.surfaceLight,

                borderRadius: BorderRadius.circular(20),
              ),

              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppText.formTitle.copyWith(
                        color: AppColors.primaryMaroon,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      body,
                      style: AppText.formDescription.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),

                                side: const BorderSide(
                                  color: AppColors.primaryMaroon,

                                  width: 1,
                                ),
                              ),
                            ),

                            onPressed: () {
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                              }
                            },

                            child: Text(
                              'Close',

                              style: AppText.button.copyWith(
                                color: AppColors.primaryMaroon,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            style: AppButtons.primary,

                            onPressed: () {
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                              }

                              if (context.mounted) {
                                pageMessage(
                                  'You agreed to our terms and conditions.',
                                  context,
                                  AppColors.success,
                                );
                              }
                            },

                            child: Text(
                              'I Agree',

                              style: AppText.button.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildLoadingOverlay() {
    if (!mounted) return const SizedBox.shrink();
    final isLoading = ref.watch(
      rescueOnboardingProvider.select((v) => v.isLoading),
    );

    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return pageLoading(context);
  }

  Widget _buildLogo() {
    return Center(
      child: Image.asset(
        'assets/images/app_bg_removed.webp',
        height: 120,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildTitle() {
    return const Center(child: Text('LifeLine', style: AppText.welcomeTitle));
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFirstNameField(),
          const SizedBox(height: AppSpacing.lg),
          _buildLastNameField(),
          const SizedBox(height: AppSpacing.lg),
          _buildPhoneField(),
          const SizedBox(height: AppSpacing.lg),
          Consumer(
            builder: (context, ref, child) {
              return _buildServiceSelector(ref);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Consumer(
            builder: (context, ref, child) {
              return _buildNgoDropdown(ref);
            },
          ),
          const SizedBox(height: AppSpacing.xxxl),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildServiceSelector(WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();
    final selectedService = ref.watch(
      rescueOnboardingProvider.select((v) => v.selectedService),
    );

    const services = ['Floods', 'Earthquake', 'Medical'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Service', style: AppText.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppDecorations.textFieldBorderRadius,
            border: Border.all(color: AppColors.borderColor, width: 1),
          ),
          child: Column(
            children:
                services.map((service) {
                  final isSelected =
                      selectedService?.toLowerCase() == service.toLowerCase();
                  return InkWell(
                    borderRadius: AppDecorations.textFieldBorderRadius,
                    onTap: () => _onServiceSelected(service),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: service,
                            groupValue: selectedService,
                            activeColor: AppColors.primaryMaroon,
                            onChanged: (value) {
                              if (value != null) _onServiceSelected(value);
                            },
                          ),
                          Text(
                            service,
                            style: AppText.fieldLabel.copyWith(
                              color:
                                  isSelected
                                      ? AppColors.primaryMaroon
                                      : AppColors.darkCharcoal,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFirstNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('First Name', style: AppText.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _firstNameController,
          decoration: AppTextFields.textFieldDecoration(
            'Enter your first name',
          ),
          validator: _validateName,
        ),
      ],
    );
  }

  Widget _buildLastNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Last Name', style: AppText.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _lastNameController,
          decoration: AppTextFields.textFieldDecoration('Enter your last name'),
          validator: _validateName,
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phone Number', style: AppText.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _phoneController,
          decoration: AppTextFields.textFieldDecoration('03XXXXXXXXX'),
          keyboardType: TextInputType.phone,
          validator: _validatePhone,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: AppSizes.submitButtonHeight,
      child: Consumer(
        builder: (context, ref, child) {
          if (!mounted) return const SizedBox.shrink();
          final selectedNgoId = ref.watch(
            rescueOnboardingProvider.select((v) => v.selectedNgo),
          );
          if (!mounted) return const SizedBox.shrink();
          final isSubmitted = ref.watch(
            rescueOnboardingProvider.select((v) => v.isSubmitting),
          );
          if (!mounted) return const SizedBox.shrink();
          final isGoogleAuthenticated = ref.watch(
            rescueOnboardingProvider.select((v) => v.googleAuthenticated),
          );

          if (isGoogleAuthenticated == false) {
            return GoogleAuthentication(ref);
          }

          return ElevatedButton(
            onPressed:
                isSubmitted
                    ? null
                    : () {
                      if (_formKey.currentState!.validate()) {
                        if (selectedNgoId == null) {
                          pageMessage(
                            'Please select an NGO.',
                            context,
                            AppColors.error,
                          );
                          return;
                        }
                        _handleSubmit(selectedNgoId);
                      }
                    },
            style: AppButtons.submit,
            child:
                isSubmitted
                    ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text('Send Request', style: AppText.submitButton),
          );
        },
      ),
    );
  }

  Widget _buildNgoLogo(String ngoName) {
    return Container(
      width: 48,
      height: 48,
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
              child: const Icon(
                Icons.business,
                color: AppColors.primaryMaroon,
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNgoDropdown(WidgetRef ref) {
    if (!mounted) return const SizedBox.shrink();

    final selectedService = ref.watch(
      rescueOnboardingProvider.select((v) => v.selectedService),
    );

    // Gate: service must be selected first
    if (selectedService == null) {
      return const SizedBox.shrink();
    }

    final isNgoLoading = ref.watch(
      rescueOnboardingProvider.select((v) => v.isNgoLoading),
    );

    final approvedNgos = ref.watch(
      rescueOnboardingProvider.select((v) => v.approvedNgos),
    );

    final selectedNgoId = ref.watch(
      rescueOnboardingProvider.select((v) => v.selectedNgo),
    );

    final isExpanded = ref.watch(
      rescueOnboardingProvider.select((v) => v.isDropdownExpanded),
    );

    final selectedNgo = approvedNgos.firstWhere(
      (ngo) => ngo['docId'] == selectedNgoId,
      orElse: () => {},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select NGO', style: AppText.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        // Show a circular loader while NGOs are being fetched
        if (isNgoLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryMaroon,
                ),
              ),
            ),
          )
        else ...[
          _buildDropdownHeader(isExpanded, selectedNgo),
          if (isExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildDropdownList(approvedNgos),
          ],
        ],
      ],
    );
  }

  Widget _buildDropdownHeader(
    bool isExpanded,
    Map<String, dynamic> selectedNgo,
  ) {
    return GestureDetector(
      onTap: () {
        if (mounted) {
          ref
              .read(rescueOnboardingProvider.notifier)
              .setIsDropdownExpanded(!isExpanded);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppDecorations.textFieldBorderRadius,
          border: Border.all(color: AppColors.borderColor, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedNgo.isEmpty
                    ? 'Select an NGO'
                    : selectedNgo['ngoName'] ?? 'Select an NGO',
                style:
                    selectedNgo.isEmpty
                        ? AppText.textFieldHint
                        : AppText.fieldLabel.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownList(List<Map<String, dynamic>> approvedNgos) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDecorations.textFieldBorderRadius,
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child:
          approvedNgos.isEmpty
              ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No NGOs available', style: AppText.small),
                ),
              )
              : ListView.builder(
                shrinkWrap: true,
                itemCount: approvedNgos.length,
                itemBuilder: (context, index) {
                  final ngo = approvedNgos[index];
                  return _buildNgoListItem(ngo);
                },
              ),
    );
  }

  Widget _buildNgoListItem(Map<String, dynamic> ngo) {
    final ngoName = ngo['ngoName'] ?? 'Unknown NGO';
    final branchName = ngo['branchName'] ?? 'N/A';
    final serviceType = ngo['selectedProgram'] ?? 'N/A';
    final docId = ngo['docId'] ?? '';

    return Consumer(
      builder: (context, ref, child) {
        if (!mounted) return const SizedBox.shrink();
        final selectedNgoId = ref.watch(
          rescueOnboardingProvider.select((v) => v.selectedNgo),
        );

        return ListTile(
          onTap: () {
            if (mounted) {
              ref.read(rescueOnboardingProvider.notifier).setSelectedNgo(docId);
              ref
                  .read(rescueOnboardingProvider.notifier)
                  .setIsDropdownExpanded(false);
            }
          },
          selected: selectedNgoId == docId,
          selectedTileColor: AppColors.primaryMaroon.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Row(
            children: [
              // NGO Logo
              _buildNgoLogo(ngoName),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ngoName,
                      style: AppText.fieldLabel.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      branchName,
                      style: AppText.small.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Service: $serviceType',
                      style: AppText.small.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
