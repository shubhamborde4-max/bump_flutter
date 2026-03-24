import 'package:flutter_contacts/flutter_contacts.dart';

class ContactService {
  /// Save a prospect's info as a phone contact.
  /// Returns true if saved successfully.
  static Future<bool> saveToContacts({
    required String firstName,
    required String lastName,
    String? phone,
    String? email,
    String? company,
    String? title,
    String? linkedIn,
    String? note,
  }) async {
    // Request permission
    if (!await FlutterContacts.requestPermission()) {
      return false;
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
    return true;
  }
}
