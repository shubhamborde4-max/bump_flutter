import 'package:flutter_contacts/flutter_contacts.dart';

class ContactService {
  /// Save a prospect's info as a phone contact.
  /// Returns 'saved' if new contact created, 'exists' if already saved, 'denied' if permission denied.
  static Future<String> saveToContacts({
    required String firstName,
    required String lastName,
    String? phone,
    String? email,
    String? company,
    String? title,
    String? linkedIn,
    String? note,
  }) async {
    if (!await FlutterContacts.requestPermission()) {
      return 'denied';
    }

    // Check for duplicate: match by name + (phone or email)
    final existing = await FlutterContacts.getContacts(
      withProperties: true,
    );

    final fullName = '$firstName $lastName'.trim().toLowerCase();
    for (final c in existing) {
      final cName = '${c.name.first} ${c.name.last}'.trim().toLowerCase();
      if (cName == fullName) {
        // Name matches — check phone or email
        final hasMatchingPhone = phone != null && phone.isNotEmpty &&
            c.phones.any((p) => p.number.replaceAll(RegExp(r'[^0-9+]'), '') == phone.replaceAll(RegExp(r'[^0-9+]'), ''));
        final hasMatchingEmail = email != null && email.isNotEmpty &&
            c.emails.any((e) => e.address.toLowerCase() == email.toLowerCase());

        if (hasMatchingPhone || hasMatchingEmail || (phone == null && email == null)) {
          return 'exists';
        }
      }
    }

    final contact = Contact(
      name: Name(first: firstName, last: lastName),
      phones: [
        if (phone != null && phone.isNotEmpty) Phone(phone, label: PhoneLabel.work),
      ],
      emails: [
        if (email != null && email.isNotEmpty) Email(email),
      ],
      organizations: [
        if (company != null && company.isNotEmpty)
          Organization(company: company, title: title ?? ''),
      ],
      websites: [
        if (linkedIn != null && linkedIn.isNotEmpty)
          Website(linkedIn, label: WebsiteLabel.other),
      ],
      notes: [
        if (note != null && note.isNotEmpty) Note(note),
      ],
    );

    await contact.insert();
    return 'saved';
  }
}
