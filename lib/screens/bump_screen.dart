import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/providers/profile_provider.dart';
import 'package:bump/providers/exchange_provider.dart';
import 'package:bump/providers/prospects_provider.dart';
import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/widgets/avatar.dart';
import 'package:bump/widgets/glass_card.dart';
import 'package:bump/widgets/qr_display_widget.dart';
import 'package:bump/widgets/quick_capture_sheet.dart';
import 'package:bump/services/contact_service.dart';
import 'package:bump/services/nfc_hce_service.dart';

/// The possible states of the NFC bump tab.
enum _NfcState { checking, available, unavailable, exchangeSuccess }

class BumpScreen extends ConsumerStatefulWidget {
  const BumpScreen({super.key});

  @override
  ConsumerState<BumpScreen> createState() => _BumpScreenState();
}

class _BumpScreenState extends ConsumerState<BumpScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0 = Bump, 1 = QR Code

  _NfcState _nfcState = _NfcState.checking;
  bool _nfcSessionActive = false;

  /// Holds the exchanged contact info after a successful NFC exchange.
  Map<String, dynamic>? _exchangeResult;

  /// Quick Capture queue for rapid sharing
  final List<Map<String, dynamic>> _quickCaptureQueue = [];
  bool _isShowingQuickCapture = false;
  int _consecutiveSkips = 0;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
    _startHceService();
  }

  @override
  void dispose() {
    _stopNfcSession();
    _stopHceService();
    super.dispose();
  }

  /// Start the HCE service so the phone acts as an NFC tag with the user's vCard.
  Future<void> _startHceService() async {
    try {
      final supported = await NfcHceService.isSupported;
      if (!supported) return;

      final profile = ref.read(profileNotifierProvider).valueOrNull;
      if (profile == null) return;

      // Build and set the vCard
      final vcf = NfcHceService.buildVCard(
        firstName: profile.firstName,
        lastName: profile.lastName,
        email: profile.email,
        phone: profile.phone,
        mobileNumber: profile.mobileNumber,
        company: profile.company,
        title: profile.title,
        website: profile.website,
        address: profile.address,
        linkedIn: profile.linkedIn,
        note: profile.note,
      );
      await NfcHceService.setVCard(vcf);
      await NfcHceService.enable();
    } catch (e) {
      debugPrint('HCE start failed: $e');
    }
  }

  Future<void> _stopHceService() async {
    try {
      await NfcHceService.disable();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // NFC helpers
  // ---------------------------------------------------------------------------

  Future<void> _checkNfcAvailability() async {
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      if (!mounted) return;
      setState(() {
        _nfcState = isAvailable ? _NfcState.available : _NfcState.unavailable;
      });
      if (isAvailable) {
        _startNfcSession();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _nfcState = _NfcState.unavailable);
    }
  }

  void _startNfcSession() {
    if (_nfcSessionActive) return;

    final profile = ref.read(profileNotifierProvider).valueOrNull;
    final currentUserId = profile?.id ?? '';
    if (currentUserId.isEmpty) return;

    final activeEvent = ref.read(activeEventProvider);
    final eventId = activeEvent?.id ?? '';

    setState(() => _nfcSessionActive = true);

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          NfcManager.instance.stopSession(
            errorMessage: 'Tag does not support NDEF.',
          );
          if (mounted) setState(() => _nfcSessionActive = false);
          return;
        }

        // ----- READ incoming exchange URL -----
        String? otherUserId;
        if (ndef.cachedMessage != null) {
          for (final record in ndef.cachedMessage!.records) {
            final payload = String.fromCharCodes(record.payload);
            // URI records may have a prefix byte; strip it.
            final cleaned = payload.startsWith('\u0000')
                ? payload.substring(1)
                : payload;
            if (cleaned.contains('bump://exchange/')) {
              final uri = Uri.tryParse(
                cleaned.substring(cleaned.indexOf('bump://exchange/')),
              );
              if (uri != null) {
                otherUserId = uri.pathSegments.isNotEmpty
                    ? uri.pathSegments.last
                    : null;
              }
            }
          }
        }

        // ----- WRITE our exchange URL -----
        if (ndef.isWritable) {
          try {
            final exchangeUri = eventId.isNotEmpty
                ? Uri.parse('bump://exchange/$currentUserId?event=$eventId')
                : Uri.parse('bump://exchange/$currentUserId');
            final message = NdefMessage([
              NdefRecord.createUri(exchangeUri),
            ]);
            await ndef.write(message);
          } catch (_) {
            // Write may fail on some tags — that is acceptable.
          }
        }

        NfcManager.instance.stopSession();
        if (mounted) setState(() => _nfcSessionActive = false);

        // ----- Perform the exchange -----
        if (otherUserId != null && otherUserId.isNotEmpty) {
          await _performExchange(otherUserId, eventId);
        } else {
          // One-way share — trigger Quick Capture
          if (mounted) {
            _enqueueQuickCapture(eventId);
            _startNfcSession();
          }
        }
      },
      onError: (error) async {
        NfcManager.instance.stopSession(errorMessage: error.toString());
        if (mounted) {
          setState(() => _nfcSessionActive = false);
          // Restart the session so the user can try again.
          _startNfcSession();
        }
      },
    );
  }

  void _stopNfcSession() {
    if (_nfcSessionActive) {
      NfcManager.instance.stopSession();
      _nfcSessionActive = false;
    }
  }

  Future<void> _performExchange(String otherUserId, String eventId) async {
    try {
      final repo = ref.read(exchangeRepositoryProvider);
      final result = await repo.performExchange(
        receiverId: otherUserId,
        method: 'nfc',
        eventId: eventId.isNotEmpty ? eventId : null,
      );

      if (!mounted) return;
      setState(() {
        _exchangeResult = result;
        _nfcState = _NfcState.exchangeSuccess;
      });

      // Refresh the prospects list so the recent-exchanges section updates.
      ref.invalidate(prospectsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exchange failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Resume listening.
      _startNfcSession();
    }
  }

  void _enqueueQuickCapture(String eventId) {
    final activeEvent = ref.read(activeEventProvider);
    _quickCaptureQueue.add({
      'eventId': activeEvent?.id ?? eventId,
      'eventName': activeEvent?.name,
      'timestamp': DateTime.now(),
    });
    _processQuickCaptureQueue();
  }

  Future<void> _processQuickCaptureQueue() async {
    if (_isShowingQuickCapture || _quickCaptureQueue.isEmpty || !mounted) return;
    _isShowingQuickCapture = true;

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) {
      _isShowingQuickCapture = false;
      return;
    }

    final item = _quickCaptureQueue.removeAt(0);
    await showQuickCaptureSheet(
      context,
      ref,
      eventId: item['eventId'] as String?,
      eventName: item['eventName'] as String?,
    );

    _isShowingQuickCapture = false;
    // Process next in queue
    if (mounted && _quickCaptureQueue.isNotEmpty) {
      _processQuickCaptureQueue();
    }
  }

  void _resetNfc() {
    setState(() {
      _nfcState = _NfcState.available;
      _exchangeResult = null;
    });
    _startNfcSession();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final recentProspects = ref.watch(recentProspectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Exchange',
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
            const SizedBox(height: 8),

            // Segmented Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildTabButton('Bump', 0),
                    _buildTabButton('QR Code', 1),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tab Content
            Expanded(
              child: _selectedTab == 0 ? _buildBumpTab() : _buildQrTab(),
            ),

            // Recent Exchanges
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Exchanges',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: recentProspects.isEmpty
                  ? Center(
                      child: Text(
                        'No exchanges yet',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: recentProspects.length > 3
                          ? 3
                          : recentProspects.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final prospect = recentProspects[index];
                        return _buildExchangeRow(prospect);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab button
  // ---------------------------------------------------------------------------

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bump tab — NFC
  // ---------------------------------------------------------------------------

  Widget _buildBumpTab() {
    switch (_nfcState) {
      case _NfcState.checking:
        return _buildCheckingState();
      case _NfcState.available:
        return _buildNfcAvailableState();
      case _NfcState.unavailable:
        return _buildNfcUnavailableState();
      case _NfcState.exchangeSuccess:
        return _buildExchangeSuccessState();
    }
  }

  // -- Checking --------------------------------------------------------------

  Widget _buildCheckingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Checking NFC...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // -- NFC Available ----------------------------------------------------------

  Widget _buildNfcAvailableState() {
    final profileAsync = ref.watch(profileNotifierProvider);
    final userId = profileAsync.valueOrNull?.id ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing concentric rings
        _buildPulsingRings(),

        const SizedBox(height: 32),

        Text(
          'Hold phones together',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 8),

        Text(
          'Listening for NFC...',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

        const SizedBox(height: 32),

        // Share Link Instead button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: GestureDetector(
            onTap: () {
              final link = 'bump://exchange/$userId';
              Share.share('Connect with me on Bump! $link');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.share2,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Share Link Instead',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 24),
      ],
    );
  }

  /// Concentric pulsing rings with a phone icon in the centre.
  Widget _buildPulsingRings() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          _buildRing(200, 0),
          // Middle ring
          _buildRing(160, 200),
          // Inner ring
          _buildRing(120, 400),
          // Centre icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.hero,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.smartphone,
              size: 36,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRing(double size, int delayMs) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 2,
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .scaleXY(
          begin: 0.85,
          end: 1.0,
          duration: 1500.ms,
          delay: Duration(milliseconds: delayMs),
          curve: Curves.easeInOut,
        )
        .fadeIn(
          duration: 600.ms,
          delay: Duration(milliseconds: delayMs),
        );
  }

  // -- NFC Unavailable --------------------------------------------------------

  Widget _buildNfcUnavailableState() {
    final profileAsync = ref.watch(profileNotifierProvider);
    final userId = profileAsync.valueOrNull?.id ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceLight,
          ),
          child: Icon(
            LucideIcons.smartphoneNfc,
            size: 44,
            color: AppColors.textMuted,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'NFC not available',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Use QR Code or share your profile link',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Open QR Code button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = 1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppGradients.hero,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.qrCode,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Open QR Code',
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
        ),

        const SizedBox(height: 12),

        // Share Link button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: GestureDetector(
            onTap: () {
              final link = 'bump://exchange/$userId';
              Share.share('Connect with me on Bump! $link');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.share2,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Share Link',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  // -- Exchange Success -------------------------------------------------------

  Widget _buildExchangeSuccessState() {
    // The RPC returns { exchange_id, receiver: { id, first_name, ... } }
    final receiver = _exchangeResult?['receiver'] as Map<String, dynamic>? ?? _exchangeResult ?? {};
    final name = receiver['first_name'] as String? ?? '';
    final lastName = receiver['last_name'] as String? ?? '';
    final company = receiver['company'] as String? ?? '';
    final fullName = '$name $lastName'.trim();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success checkmark
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.hero,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.checkCircle,
            size: 48,
            color: Colors.white,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: 500.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 300.ms),

        const SizedBox(height: 24),

        Text(
          'Exchange Successful!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 8),

        if (fullName.isNotEmpty)
          Text(
            fullName,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

        if (company.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              company,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ),

        const SizedBox(height: 32),

        // View Profile button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: GestureDetector(
            onTap: () {
              final recv = _exchangeResult?['receiver'] as Map<String, dynamic>? ?? _exchangeResult ?? {};
              final recvId = recv['id'] as String?;
              if (recvId != null) {
                // Navigate to prospect list filtered by this exchange
                context.push('/prospects/$recvId');
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppGradients.hero,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.user,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View Profile',
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
        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

        const SizedBox(height: 12),

        // Save to Contacts button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: GestureDetector(
            onTap: () async {
              final recv = _exchangeResult?['receiver'] as Map<String, dynamic>? ?? _exchangeResult ?? {};
              final firstName = recv['first_name'] as String? ?? '';
              final lastName = recv['last_name'] as String? ?? '';
              final email = recv['email'] as String? ?? '';
              final phone = recv['phone'] as String? ?? '';
              final company = recv['company'] as String? ?? '';
              final title = recv['title'] as String? ?? '';
              final linkedIn = recv['linkedin'] as String?;

              final result = await ContactService.saveToContacts(
                firstName: firstName,
                lastName: lastName,
                phone: phone.isNotEmpty ? phone : null,
                email: email.isNotEmpty ? email : null,
                company: company.isNotEmpty ? company : null,
                title: title.isNotEmpty ? title : null,
                linkedIn: linkedIn,
              );
              if (!mounted) return;
              final (msg, color) = switch (result) {
                'saved' => ('Contact saved!', Colors.green.shade600),
                'exists' => ('Contact already saved', Colors.blue.shade600),
                _ => ('Permission denied', Colors.red.shade600),
              };
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: color,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF4CAF50),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.userPlus,
                    size: 18,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Save to Contacts',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 550.ms, duration: 400.ms),

        const SizedBox(height: 12),

        // Exchange again button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: GestureDetector(
            onTap: _resetNfc,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.refreshCw,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Exchange Again',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // QR tab (unchanged)
  // ---------------------------------------------------------------------------

  Widget _buildQrTab() {
    final profileAsync = ref.watch(profileNotifierProvider);
    final activeEvent = ref.watch(activeEventProvider);
    final userId = profileAsync.valueOrNull?.id ?? '';
    final eventId = activeEvent?.id ?? '';

    final qrData = eventId.isNotEmpty
        ? 'bump://exchange/$userId?event=$eventId'
        : 'bump://exchange/$userId';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // QR code display
        QrDisplayWidget(
          data: qrData,
          size: 200,
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: 400.ms,
            ),

        const SizedBox(height: 12),

        Text(
          'Your QR Code',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),

        const SizedBox(height: 24),

        // Scan QR button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: GestureDetector(
            onTap: () {
              context.push('/qr-scanner');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.scan,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scan QR',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Recent exchange row (unchanged)
  // ---------------------------------------------------------------------------

  Widget _buildExchangeRow(Prospect prospect) {
    final timeAgo = _formatTimeAgo(prospect.exchangeTime);

    // Ghost exchange display
    final isGhost = prospect.firstName.isEmpty && prospect.exchangeType == 'quick_capture';

    return GestureDetector(
      onTap: () => context.push('/prospects/${prospect.id}'),
      child: GlassCard(
        opacity: 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                BumpAvatar(
                  firstName: isGhost ? '?' : prospect.firstName,
                  lastName: isGhost ? '' : prospect.lastName,
                  uri: prospect.avatar,
                  size: 36,
                ),
                if (prospect.isPartial)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(LucideIcons.alertCircle,
                          size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGhost
                        ? 'NFC share at ${_formatTimeAgo(prospect.exchangeTime)}'
                        : prospect.fullName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isGhost ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isGhost ? 'No contact captured' : prospect.company,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isGhost)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Add details',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              )
            else ...[
              Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                timeAgo,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
