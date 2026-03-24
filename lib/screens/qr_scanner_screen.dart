import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:bump/core/theme/app_theme.dart';
import 'package:bump/providers/exchange_provider.dart';
import 'package:bump/services/contact_service.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final rawValue = barcode.rawValue!;

    // Parse the URL: bump://exchange/{userId}?event={eventId}
    String? userId;
    String? eventId;

    try {
      final uri = Uri.parse(rawValue);
      if (uri.scheme == 'bump' && uri.host == 'exchange') {
        userId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        eventId = uri.queryParameters['event'];
      } else if (rawValue.contains('bump://exchange/')) {
        // Fallback parsing
        final parts = rawValue.replaceFirst('bump://exchange/', '').split('?');
        userId = parts.first;
        if (parts.length > 1) {
          final params = Uri.splitQueryString(parts[1]);
          eventId = params['event'];
        }
      }
    } catch (_) {
      // Not a valid bump URL
    }

    if (userId == null || userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid QR code'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);
    _controller.stop();

    try {
      final exchangeRepo = ref.read(exchangeRepositoryProvider);
      final result = await exchangeRepo.performExchange(
        receiverId: userId,
        method: 'qr',
        eventId: eventId,
      );

      if (mounted) {
        // The RPC returns { exchange_id, receiver: { id, first_name, ... } }
        final receiver = result['receiver'] as Map<String, dynamic>? ?? result;
        final exchangedName =
            '${receiver['first_name'] ?? ''} ${receiver['last_name'] ?? ''}'.trim();

        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.hero,
                  ),
                  child: const Icon(
                    LucideIcons.checkCircle2,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Exchange Successful!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: Text(
              exchangedName.isNotEmpty
                  ? 'You exchanged contact info with $exchangedName.'
                  : 'Contact info exchanged successfully.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final firstName = receiver['first_name'] as String? ?? '';
                  final lastName = receiver['last_name'] as String? ?? '';
                  final email = (result['receiver'] != null ? receiver['email'] : result['email']) as String? ?? '';
                  final phone = (result['receiver'] != null ? receiver['phone'] : result['phone']) as String? ?? '';
                  final company = receiver['company'] as String? ?? '';
                  final title = receiver['title'] as String? ?? '';
                  final saved = await ContactService.saveToContacts(
                    firstName: firstName,
                    lastName: lastName,
                    phone: phone.isNotEmpty ? phone : null,
                    email: email.isNotEmpty ? email : null,
                    company: company.isNotEmpty ? company : null,
                    title: title.isNotEmpty ? title : null,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(saved ? 'Contact saved!' : 'Permission denied'),
                        backgroundColor: saved ? Colors.green.shade600 : Colors.red.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                child: Text(
                  'Save Contact',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Done',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );

        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exchange failed: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() => _isProcessing = false);
        _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay with cutout
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          // Bottom instruction
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isProcessing
                      ? 'Processing exchange...'
                      : 'Point camera at a Bump QR code',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5341CD),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
