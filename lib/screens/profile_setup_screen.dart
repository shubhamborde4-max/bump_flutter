import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/data/models/user_model.dart';
import 'package:bump/providers/profile_provider.dart';
import 'package:bump/widgets/gradient_button.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _currentStep = 0;
  static const _totalSteps = 3;
  bool _isLoading = false;

  // Step 1: Basic Info
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();

  // Username availability
  bool? _isUsernameAvailable;
  bool _isCheckingUsername = false;
  Timer? _usernameDebounce;

  // Step 2: Professional
  final _companyController = TextEditingController();
  final _titleController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _websiteController = TextEditingController();

  // Step 3: Card Style
  CardStyle _selectedCardStyle = CardStyle.modern;

  @override
  void initState() {
    super.initState();
    _prefillEmail();
    _usernameController.addListener(_onUsernameChanged);
  }

  void _prefillEmail() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.email != null) {
      _emailController.text = user.email!;
    }
  }

  void _onUsernameChanged() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final repo = ref.read(profileRepositoryProvider);
        final available = await repo.isUsernameAvailable(username);
        if (mounted && _usernameController.text.trim() == username) {
          setState(() {
            _isUsernameAvailable = available;
            _isCheckingUsername = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isCheckingUsername = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _companyController.dispose();
    _titleController.dispose();
    _linkedInController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _onComplete();
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // BUG-020: Normalize URL by prepending https:// if missing
  String? _normalizeUrl(String url) {
    if (url.isEmpty) return null;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty || !uri.host.contains('.')) return null;
      return url;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onComplete() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // BUG-020: Validate and normalize LinkedIn URL
      String? linkedInUrl;
      if (_linkedInController.text.trim().isNotEmpty) {
        linkedInUrl = _normalizeUrl(_linkedInController.text.trim());
        if (linkedInUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enter a valid LinkedIn URL'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // BUG-020: Validate and normalize Website URL
      String? websiteUrl;
      if (_websiteController.text.trim().isNotEmpty) {
        websiteUrl = _normalizeUrl(_websiteController.text.trim());
        if (websiteUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enter a valid website URL'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final user = User(
        id: userId,
        username: _usernameController.text.trim().toLowerCase(),
        firstName: _firstNameController.text.isNotEmpty
            ? _firstNameController.text.trim()
            : 'User',
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        company: _companyController.text.trim(),
        title: _titleController.text.trim(),
        linkedIn: linkedInUrl,
        website: websiteUrl,
        cardStyle: _selectedCardStyle,
      );

      final profileRepo = ref.read(profileRepositoryProvider);

      // Check if profile already exists
      final existing = await profileRepo.getMyProfile();
      if (existing != null) {
        await profileRepo.updateProfile(user);
      } else {
        await profileRepo.createProfile(user);
      }

      if (!mounted) return;

      // Invalidate profile provider so it refetches
      ref.invalidate(profileProvider);
      ref.invalidate(profileNotifierProvider);

      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _totalSteps;
    final isLastStep = _currentStep == _totalSteps - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: _onBack,
              )
            : null,
        title: Text(
          'Profile Setup',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Progress indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalSteps, (index) {
                      final isActive = index == _currentStep;
                      final isCompleted = index < _currentStep;
                      return Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive || isCompleted
                                  ? AppColors.primary
                                  : AppColors.surfaceLight,
                              border: isActive
                                  ? Border.all(
                                      color: AppColors.accent,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? Colors.white
                                            : AppColors.textMuted,
                                      ),
                                    ),
                            ),
                          ),
                          if (index < _totalSteps - 1)
                            Container(
                              width: 40,
                              height: 2,
                              color: isCompleted
                                  ? AppColors.primary
                                  : AppColors.surfaceLight,
                            ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildStepContent(),
                ),
              ),
            ),

            // Next / Complete button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: GradientButton(
                title: _isLoading
                    ? 'Saving...'
                    : (isLastStep ? 'Complete Setup' : 'Next'),
                disabled: _isLoading,
                onTap: _isLoading ? null : _onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildProfessionalStep();
      case 2:
        return _buildCardStyleStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      key: const ValueKey('step_0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tell us about yourself',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),

        // Username field with availability check
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Username',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              maxLength: 30,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              decoration: InputDecoration(
                hintText: 'johndoe',
                prefixIcon: const Icon(Icons.alternate_email,
                    color: AppColors.textMuted, size: 20),
                suffixIcon: _isCheckingUsername
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _isUsernameAvailable == true
                        ? const Icon(Icons.check_circle,
                            color: AppColors.success, size: 20)
                        : _isUsernameAvailable == false
                            ? const Icon(Icons.cancel,
                                color: Colors.red, size: 20)
                            : null,
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
            if (_isUsernameAvailable == false)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'Username is already taken',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _firstNameController,
          label: 'First Name',
          hint: 'John',
          maxLength: 50,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _lastNameController,
          label: 'Last Name',
          hint: 'Doe',
          maxLength: 50,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'john@example.com',
          keyboardType: TextInputType.emailAddress,
          maxLength: 255,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone',
          hint: '+1 (555) 000-0000',
          keyboardType: TextInputType.phone,
          maxLength: 20,
        ),
      ],
    );
  }

  Widget _buildProfessionalStep() {
    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professional Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Where do you work?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _companyController,
          label: 'Company',
          hint: 'Acme Inc.',
          maxLength: 100,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _titleController,
          label: 'Job Title',
          hint: 'Product Manager',
          maxLength: 100,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _linkedInController,
          label: 'LinkedIn',
          hint: 'linkedin.com/in/johndoe',
          keyboardType: TextInputType.url,
          maxLength: 500,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _websiteController,
          label: 'Website',
          hint: 'johndoe.com',
          keyboardType: TextInputType.url,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildCardStyleStep() {
    return Column(
      key: const ValueKey('step_2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Style',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose how your card looks',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),
        ...CardStyle.values.map((style) {
          final isSelected = _selectedCardStyle == style;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCardStyle = style),
              child: _buildCardPreview(style, isSelected),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCardPreview(CardStyle style, bool isSelected) {
    final borderColor =
        isSelected ? AppColors.primary : AppColors.surfaceLight;
    final borderWidth = isSelected ? 2.0 : 1.0;

    LinearGradient? cardGradient;
    Color cardBg = AppColors.surface;
    Color cardTextColor = AppColors.textPrimary;

    switch (style) {
      case CardStyle.modern:
        cardGradient = AppGradients.hero;
        cardTextColor = Colors.white;
        break;
      case CardStyle.classic:
        cardBg = AppColors.surface;
        break;
      case CardStyle.minimal:
        cardBg = AppColors.surfaceLight;
        break;
    }

    final styleName =
        style.name[0].toUpperCase() + style.name.substring(1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: cardGradient,
        color: cardGradient == null ? cardBg : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardGradient != null
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.surfaceLight,
            ),
            child: Icon(
              Icons.person,
              color: cardGradient != null
                  ? Colors.white
                  : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  styleName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cardTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  style == CardStyle.modern
                      ? 'Bold gradient design'
                      : style == CardStyle.classic
                          ? 'Clean white background'
                          : 'Subtle light design',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cardGradient != null
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardGradient != null
                    ? Colors.white
                    : AppColors.primary,
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: cardGradient != null
                    ? AppColors.primary
                    : Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLengthEnforcement: maxLength != null ? MaxLengthEnforcement.enforced : null,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
