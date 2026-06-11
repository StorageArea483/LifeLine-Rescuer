import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_line_rescuer/styles/styles.dart';
import 'package:life_line_rescuer/providers/rescuer_onboarding_provider.dart';

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

  // Firebase configuration for life-line-ngo
  static const FirebaseOptions _ngoFirebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyBeieryGaw4bh4dtbrI54qsIc51XkP6SoM',
    appId: '1:169949190544:web:2640453ce5dd2aa55d3b15',
    messagingSenderId: '169949190544',
    projectId: 'life-line-ngo',
    authDomain: 'life-line-ngo.firebaseapp.com',
    storageBucket: 'life-line-ngo.firebasestorage.app',
  );

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
      // Initialize life-line-ngo Firebase
      final ngoApp = await Firebase.initializeApp(
        name: 'life-line-ngo',
        options: _ngoFirebaseOptions,
      );

      _ngoFirestore = FirebaseFirestore.instanceFor(app: ngoApp);

      // Fetch approved NGOs once
      await _fetchApprovedNgos();

      if (mounted) {
        ref.read(rescueOnboardingProvider.notifier).setLoading(false);
      }
    } catch (e) {
      if (mounted) {
        ref.read(rescueOnboardingProvider.notifier).setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred please retry'),
          ),
        );
      }
    }
  }

  Future<void> _fetchApprovedNgos() async {
    if (_ngoFirestore == null) return;

    try {
      if (mounted) {
        ref.read(rescueOnboardingProvider.notifier).setApprovedNgos([]);
      }

      // Get the data once
      final snapshot =
          await _ngoFirestore!
              .collection('ngo-info-database')
              .where('approved', isEqualTo: true)
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
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: AppContainers.pageContainer,
            child: SafeArea(child: _buildBody()),
          ),
          _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBody() {
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
          const SizedBox(height: AppSpacing.xl),
          _buildTitle(),
          const SizedBox(height: AppSpacing.xxxl),
          _buildForm(),
        ],
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

    return Container(
      color: AppColors.softBackground,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMaroon),
        ),
      ),
    );
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
              return _buildNgoDropdown(ref);
            },
          ),
          const SizedBox(height: AppSpacing.xxxl),
          _buildSubmitButton(),
        ],
      ),
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

          return ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (selectedNgoId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an NGO')),
                  );
                  return;
                }
                // Form is valid, proceed with onboarding
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Onboarding successful!')),
                );
              }
            },
            style: AppButtons.submit,
            child: const Text('Send Request', style: AppText.submitButton),
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
    final approvedNgos = ref.watch(
      rescueOnboardingProvider.select((v) => v.approvedNgos),
    );

    if (!mounted) return const SizedBox.shrink();
    final selectedNgoId = ref.watch(
      rescueOnboardingProvider.select((v) => v.selectedNgo),
    );

    if (!mounted) return const SizedBox.shrink();
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
        _buildDropdownHeader(isExpanded, selectedNgo),
        if (isExpanded) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildDropdownList(approvedNgos),
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
