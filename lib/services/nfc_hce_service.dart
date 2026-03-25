import 'package:flutter/services.dart';

/// Flutter interface to the native NFC Host Card Emulation (HCE) service.
///
/// When enabled, the phone emulates an NFC Type 4 Tag containing a vCard.
/// Any phone that taps this device will read the tag and offer to save the
/// contact — no app required on the other end.
class NfcHceService {
  static const _channel = MethodChannel('com.shubhamborde.bump/nfc_hce');

  /// Whether the device hardware supports HCE.
  static Future<bool> get isSupported async {
    try {
      return await _channel.invokeMethod<bool>('isHceSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Build a vCard string from user profile fields.
  static String buildVCard({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? mobileNumber,
    String? company,
    String? title,
    String? website,
    String? address,
    String? linkedIn,
    String? note,
  }) {
    final buf = StringBuffer()
      ..writeln('BEGIN:VCARD')
      ..writeln('VERSION:3.0')
      ..writeln('N:$lastName;$firstName;;;')
      ..writeln('FN:$firstName $lastName');

    if (company != null && company.isNotEmpty) {
      buf.writeln('ORG:$company');
    }
    if (title != null && title.isNotEmpty) {
      buf.writeln('TITLE:$title');
    }
    if (phone != null && phone.isNotEmpty) {
      buf.writeln('TEL;TYPE=WORK,VOICE:$phone');
    }
    if (mobileNumber != null && mobileNumber.isNotEmpty) {
      buf.writeln('TEL;TYPE=CELL:$mobileNumber');
    }
    if (email != null && email.isNotEmpty) {
      buf.writeln('EMAIL;TYPE=WORK:$email');
    }
    if (website != null && website.isNotEmpty) {
      buf.writeln('URL:$website');
    }
    if (address != null && address.isNotEmpty) {
      buf.writeln('ADR;TYPE=WORK:;;$address;;;;');
    }
    if (linkedIn != null && linkedIn.isNotEmpty) {
      buf.writeln('X-SOCIALPROFILE;TYPE=linkedin:$linkedIn');
    }
    if (note != null && note.isNotEmpty) {
      buf.writeln('NOTE:$note');
    }
    buf.writeln('END:VCARD');
    return buf.toString();
  }

  /// Set the vCard data that will be served when another phone taps.
  static Future<void> setVCard(String vcf) async {
    await _channel.invokeMethod('setVCard', {'vcf': vcf});
  }

  /// Set a bump:// exchange URI as the NDEF payload.
  static Future<void> setExchangeUri(String uri) async {
    await _channel.invokeMethod('setExchangeUri', {'uri': uri});
  }

  /// Enable the HCE service (phone starts acting as an NFC tag).
  static Future<void> enable() async {
    await _channel.invokeMethod('enableHce');
  }

  /// Disable the HCE service.
  static Future<void> disable() async {
    await _channel.invokeMethod('disableHce');
  }
}
