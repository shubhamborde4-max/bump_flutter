import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import 'package:bump/providers/prospects_provider.dart';

// ── Design tokens ───────────────────────────────────────────────────────────
const _primary = Color(0xFF5341CD);
const _accent = Color(0xFF6C5CE7);
const _cyan = Color(0xFF00D2FF);
const _background = Color(0xFFF8F9FE);
const _surface = Color(0xFFFFFFFF);
const _surfaceLight = Color(0xFFF2F3F8);
const _textPrimary = Color(0xFF191C1F);
const _textSecondary = Color(0xFF474554);
const _textMuted = Color(0xFF787586);
const _successGreen = Color(0xFF00C853);
const _heroGradient = LinearGradient(
  colors: [Color(0xFF6C5CE7), Color(0xFF00D2FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Shows the Quick Capture bottom sheet after a one-way NFC share.
Future<void> showQuickCaptureSheet(
  BuildContext context,
  WidgetRef ref, {
  String? eventId,
  String? eventName,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _QuickCaptureSheet(eventId: eventId, eventName: eventName),
  );
}

class _QuickCaptureSheet extends ConsumerStatefulWidget {
  final String? eventId;
  final String? eventName;

  const _QuickCaptureSheet({this.eventId, this.eventName});

  @override
  ConsumerState<_QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends ConsumerState<_QuickCaptureSheet>
    with TickerProviderStateMixin {
  int _phase = 1;

  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  final _selectedTags = <String>{};
  bool _isSaved = false;

  late final PageController _pageController;
  late final AnimationController _checkAnimController;
  late final Animation<double> _checkAnimation;

  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _checkAnimController,
      curve: Curves.easeOut,
    ));
    _checkAnimController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _pageController.dispose();
    _checkAnimController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  bool get _nameValid => _nameController.text.trim().length >= 2;

  void _goToPhase2() {
    setState(() => _phase = 2);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _nameFocusNode.requestFocus();
    });
  }

  void _goToPhase3() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _phase = 3);
  }

  void _goBackToPhase2() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _phase = 3); // keep phase 3 height but show page 0
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _phase = 2);
    });
  }

  Future<void> _skipAndLogGhost() async {
    // Log a ghost exchange
    try {
      await ref.read(prospectsProvider.notifier).addQuickCaptureProspect(
            firstName: '',
            notes: 'NFC share - no contact captured',
            eventId: widget.eventId ?? '',
          );
    } catch (_) {
      // Silently fail for ghost logging
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveContact() async {
    HapticFeedback.mediumImpact();

    final name = _nameController.text.trim();
    final parts = name.split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    try {
      final created =
          await ref.read(prospectsProvider.notifier).addQuickCaptureProspect(
                firstName: firstName,
                lastName: lastName,
                company: _companyController.text.trim(),
                title: _titleController.text.trim(),
                notes: _notesController.text.trim(),
                eventId: widget.eventId ?? '',
                tags: _selectedTags.toList(),
              );

      if (!mounted) return;
      setState(() => _isSaved = true);

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show toast with View action
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$firstName added to your contacts'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'View',
              textColor: _cyan,
              onPressed: () {
                if (context.mounted) {
                  context.push('/prospects/${created.id}');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final targetHeight = _phase == 1
        ? screenHeight * 0.55
        : screenHeight * 0.85;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      height: targetHeight + bottomInset,
      decoration: const BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: _phase == 1 ? _buildPhase1() : _buildPhase2And3(),
          ),
        ],
      ),
    );
  }

  // ── Phase 1: Confirmation + Prompt ──────────────────────────────────────

  Widget _buildPhase1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Animated green checkmark
          AnimatedBuilder(
            animation: _checkAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _checkAnimation.value,
                child: child,
              );
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _successGreen,
              ),
              child: const Icon(
                LucideIcons.check,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            'Card Shared Successfully',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Your contact info was just saved on their phone.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Event pill badge
          if (widget.eventName != null && widget.eventName!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.eventName!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Motivational card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Text(
              'Want to remember who you just met? Jot down their name and a quick note while it\'s fresh.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _textSecondary,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quick Capture button
          GestureDetector(
            onTap: _goToPhase2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _heroGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.edit3, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Capture',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Skip button
          GestureDetector(
            onTap: _skipAndLogGhost,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Skip for now',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textMuted,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Phases 2 & 3 ───────────────────────────────────────────────────────

  Widget _buildPhase2And3() {
    return Column(
      children: [
        // Compressed top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.checkCircle,
                      size: 16, color: _successGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Card shared',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _successGreen,
                    ),
                  ),
                ],
              ),
              Text(
                'Step ${_phase == 2 ? '1' : '2'}/2',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildPhase2Content(),
              _buildPhase3Content(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Phase 2: Capture Form ──────────────────────────────────────────────

  Widget _buildPhase2Content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          Text(
            'Who did you just meet?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),

          const SizedBox(height: 24),

          // Name field
          _buildTextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            hint: 'Their name',
            autofocus: false,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 12),

          // Company field
          _buildTextField(
            controller: _companyController,
            hint: 'Company (optional)',
          ),

          const SizedBox(height: 12),

          // Title field
          _buildTextField(
            controller: _titleController,
            hint: 'Role / Title (optional)',
          ),

          const SizedBox(height: 24),

          // Next button
          GestureDetector(
            onTap: _nameValid ? _goToPhase3 : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _nameValid ? _primary : _surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _nameValid ? Colors.white : _textMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 18,
                    color: _nameValid ? Colors.white : _textMuted,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Skip
          Center(
            child: GestureDetector(
              onTap: _skipAndLogGhost,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Skip',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Phase 3: Notes + Tags ──────────────────────────────────────────────

  Widget _buildPhase3Content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          // Back button
          GestureDetector(
            onTap: _goBackToPhase2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.arrowLeft, size: 16, color: _textMuted),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Add a quick note',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'You\'ll thank yourself later.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),

          const SizedBox(height: 20),

          // Notes textarea
          Container(
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
              color: _surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: null,
              minLines: 4,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _textPrimary,
                height: 1.5,
              ),
              cursorColor: _primary,
              decoration: InputDecoration(
                hintText: 'What did you talk about?',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: _textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quick Tags
          Text(
            'Quick Tags',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickTags.map((tag) => _buildTagChip(tag)).toList(),
          ),

          const SizedBox(height: 28),

          // Save Contact button
          GestureDetector(
            onTap: _isSaved ? null : _saveContact,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _isSaved ? null : _heroGradient,
                color: _isSaved ? _successGreen : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (_isSaved ? _successGreen : _accent)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSaved ? LucideIcons.checkCircle : LucideIcons.check,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isSaved ? 'Saved!' : 'Save Contact',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static const _quickTags = [
    {'emoji': '\u{1F525}', 'label': 'Hot Lead'},
    {'emoji': '\u{1F91D}', 'label': 'Partner'},
    {'emoji': '\u{1F504}', 'label': 'Follow Up'},
    {'emoji': '\u{1F4BC}', 'label': 'Hiring'},
    {'emoji': '\u{1F4A1}', 'label': 'Investor'},
    {'emoji': '\u{1F3AF}', 'label': 'Custom'},
  ];

  Widget _buildTagChip(Map<String, String> tag) {
    final label = tag['label']!;
    final emoji = tag['emoji']!;
    final isActive = _selectedTags.contains(label);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (isActive) {
            _selectedTags.remove(label);
          } else {
            _selectedTags.add(label);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? _primary.withValues(alpha: 0.1)
              : _surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? _primary : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: _textPrimary,
        ),
        cursorColor: _primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: _textMuted,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
