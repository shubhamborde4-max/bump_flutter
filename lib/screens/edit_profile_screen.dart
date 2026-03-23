import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/data/models/user_model.dart';
import 'package:bump/providers/profile_provider.dart';
import 'package:bump/widgets/gradient_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _picker = ImagePicker();

  // Personal controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Work controllers
  final _companyCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _companyPhoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _companyAddressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // Images
  File? _profileImage;
  File? _companyLogoImage;
  String? _existingAvatarUrl;
  String? _existingLogoUrl;

  // Visibility toggles
  List<String> _visibleFields = [];

  bool _initialised = false;
  bool _isSaving = false;

  static const _allToggleableFields = [
    'firstName',
    'lastName',
    'email',
    'phone',
    'mobileNumber',
    'company',
    'title',
    'designation',
    'department',
    'website',
    'address',
    'companyPhone',
    'companyAddress',
    'linkedIn',
    'note',
  ];

  static const _fieldLabels = {
    'firstName': 'First Name',
    'lastName': 'Last Name',
    'email': 'Email',
    'phone': 'Phone',
    'mobileNumber': 'Mobile Number',
    'company': 'Company',
    'title': 'Title',
    'designation': 'Designation',
    'department': 'Department',
    'website': 'Website',
    'address': 'Address',
    'companyPhone': 'Company Phone',
    'companyAddress': 'Company Address',
    'linkedIn': 'LinkedIn',
    'note': 'Note',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _companyCtrl.dispose();
    _departmentCtrl.dispose();
    _designationCtrl.dispose();
    _companyPhoneCtrl.dispose();
    _websiteCtrl.dispose();
    _companyAddressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _populateFields(User user) {
    if (_initialised) return;
    _initialised = true;

    _firstNameCtrl.text = user.firstName;
    _lastNameCtrl.text = user.lastName;
    _emailCtrl.text = user.email;
    _mobileCtrl.text = user.mobileNumber ?? '';
    _phoneCtrl.text = user.phone;
    _addressCtrl.text = user.address ?? '';

    _companyCtrl.text = user.company;
    _departmentCtrl.text = user.department ?? '';
    _designationCtrl.text = user.designation ?? '';
    _companyPhoneCtrl.text = user.companyPhone ?? '';
    _websiteCtrl.text = user.website ?? '';
    _companyAddressCtrl.text = user.companyAddress ?? '';
    _noteCtrl.text = user.note ?? '';

    _existingAvatarUrl = user.avatar ?? user.profilePicUrl;
    _existingLogoUrl = user.companyLogo;
    _visibleFields = List<String>.from(user.visibleFields);
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _pickCompanyLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _companyLogoImage = File(picked.path));
    }
  }

  Future<void> _save(User currentUser) async {
    setState(() => _isSaving = true);

    try {
      // Upload profile image if changed
      String? avatarUrl = _existingAvatarUrl;
      if (_profileImage != null) {
        avatarUrl = await ref
            .read(profileNotifierProvider.notifier)
            .uploadAvatar(_profileImage!.path);
      }

      final updatedUser = currentUser.copyWith(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        mobileNumber: _mobileCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        avatar: avatarUrl,
        profilePicUrl: avatarUrl,
        company: _companyCtrl.text.trim(),
        department: _departmentCtrl.text.trim(),
        designation: _designationCtrl.text.trim(),
        companyPhone: _companyPhoneCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        companyAddress: _companyAddressCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        visibleFields: _visibleFields,
      );

      await ref
          .read(profileNotifierProvider.notifier)
          .updateProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: Text('Edit Profile', style: AppTypography.h4),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('Failed to load profile', style: AppTypography.bodyLarge),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(profileNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              title: Text('Edit Profile', style: AppTypography.h4),
            ),
            body: Center(
              child: Text('No profile found', style: AppTypography.bodyLarge),
            ),
          );
        }

        _populateFields(user);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Edit Profile', style: AppTypography.h4),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Tab bar
              Container(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2.5,
                  tabs: const [
                    Tab(text: 'Personal'),
                    Tab(text: 'Work'),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      // Tab content area
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          return AnimatedCrossFade(
                            firstChild: _buildPersonalTab(),
                            secondChild: _buildWorkTab(),
                            crossFadeState: _tabController.index == 0
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            duration: 250.ms,
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Card Visibility Section (always visible)
                      _buildVisibilitySection(),

                      const SizedBox(height: 32),

                      // Save button
                      GradientButton(
                        title: _isSaving ? 'Saving...' : 'Save Changes',
                        disabled: _isSaving,
                        onTap: _isSaving ? null : () => _save(user),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 100.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Personal Tab ─────────────────────────────────────────────────────────

  Widget _buildPersonalTab() {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Profile picture
        _buildProfilePicture(),
        const SizedBox(height: 24),

        _buildTextField(
          controller: _firstNameCtrl,
          label: 'First Name',
          icon: LucideIcons.user,
          maxLength: 50,
          textInputType: TextInputType.name,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _lastNameCtrl,
          label: 'Last Name',
          icon: LucideIcons.user,
          maxLength: 50,
          textInputType: TextInputType.name,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailCtrl,
          label: 'Email',
          icon: LucideIcons.mail,
          readOnly: true,
          textInputType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _mobileCtrl,
          label: 'Mobile Number',
          icon: LucideIcons.smartphone,
          maxLength: 15,
          textInputType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneCtrl,
          label: 'Phone Number',
          icon: LucideIcons.phone,
          maxLength: 15,
          textInputType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressCtrl,
          label: 'Address',
          icon: LucideIcons.mapPin,
          maxLength: 200,
          textInputType: TextInputType.streetAddress,
        ),
      ],
    );
  }

  Widget _buildProfilePicture() {
    ImageProvider? imageProvider;
    if (_profileImage != null) {
      imageProvider = FileImage(_profileImage!);
    } else if (_existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_existingAvatarUrl!);
    }

    return Center(
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: imageProvider == null ? AppGradients.hero : null,
                image: imageProvider != null
                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: imageProvider == null
                  ? Center(
                      child: Text(
                        _getInitials(),
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: const Icon(
                  LucideIcons.camera,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  String _getInitials() {
    final f = _firstNameCtrl.text;
    final l = _lastNameCtrl.text;
    return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'
        .toUpperCase();
  }

  // ── Work Tab ─────────────────────────────────────────────────────────────

  Widget _buildWorkTab() {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Company Logo
        _buildCompanyLogoUpload(),
        const SizedBox(height: 24),

        _buildTextField(
          controller: _companyCtrl,
          label: 'Company Name',
          icon: LucideIcons.building2,
          maxLength: 100,
          textInputType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _departmentCtrl,
          label: 'Department',
          icon: LucideIcons.layers,
          maxLength: 100,
          textInputType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _designationCtrl,
          label: 'Designation',
          icon: LucideIcons.briefcase,
          maxLength: 100,
          textInputType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _companyPhoneCtrl,
          label: 'Company Phone',
          icon: LucideIcons.phone,
          maxLength: 15,
          textInputType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _websiteCtrl,
          label: 'Website',
          icon: LucideIcons.globe,
          maxLength: 200,
          textInputType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _companyAddressCtrl,
          label: 'Company Address',
          icon: LucideIcons.mapPin,
          maxLength: 200,
          textInputType: TextInputType.streetAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _noteCtrl,
          label: 'Note',
          icon: LucideIcons.fileText,
          maxLength: 500,
          textInputType: TextInputType.multiline,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildCompanyLogoUpload() {
    ImageProvider? imageProvider;
    if (_companyLogoImage != null) {
      imageProvider = FileImage(_companyLogoImage!);
    } else if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_existingLogoUrl!);
    }

    return Center(
      child: GestureDetector(
        onTap: _pickCompanyLogo,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
            image: imageProvider != null
                ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                : null,
          ),
          child: imageProvider == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.upload,
                      size: 22,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Logo',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ── Card Visibility Section ──────────────────────────────────────────────

  Widget _buildVisibilitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.eye,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Card Visibility', style: AppTypography.h5),
                    const SizedBox(height: 2),
                    Text(
                      'Select which fields appear on your shared card',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ..._allToggleableFields.map((field) {
            final isVisible = _visibleFields.contains(field);
            return _buildToggleRow(
              label: _fieldLabels[field] ?? field,
              value: isVisible,
              onChanged: (val) {
                setState(() {
                  if (val) {
                    _visibleFields.add(field);
                  } else {
                    _visibleFields.remove(field);
                  }
                });
              },
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared TextField Builder ─────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    int? maxLength,
    TextInputType? textInputType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: textInputType,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: readOnly ? AppColors.textMuted : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: readOnly
            ? AppColors.surfaceLight.withValues(alpha: 0.6)
            : AppColors.surfaceLight,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
