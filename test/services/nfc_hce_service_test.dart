import 'package:flutter_test/flutter_test.dart';
import 'package:bump/services/nfc_hce_service.dart';

void main() {
  group('NfcHceService.buildVCard', () {
    test('builds a valid vCard with all fields', () {
      final vcf = NfcHceService.buildVCard(
        firstName: 'Sarah',
        lastName: 'Chen',
        email: 'sarah@stripe.com',
        phone: '+1234567890',
        mobileNumber: '+0987654321',
        company: 'Stripe',
        title: 'Engineering Manager',
        website: 'https://sarah.dev',
        address: '123 Market St, SF',
        linkedIn: 'https://linkedin.com/in/sarahchen',
        note: 'Met at TechConf 2026',
      );

      expect(vcf, contains('BEGIN:VCARD'));
      expect(vcf, contains('VERSION:3.0'));
      expect(vcf, contains('N:Chen;Sarah;;;'));
      expect(vcf, contains('FN:Sarah Chen'));
      expect(vcf, contains('ORG:Stripe'));
      expect(vcf, contains('TITLE:Engineering Manager'));
      expect(vcf, contains('TEL;TYPE=WORK,VOICE:+1234567890'));
      expect(vcf, contains('TEL;TYPE=CELL:+0987654321'));
      expect(vcf, contains('EMAIL;TYPE=WORK:sarah@stripe.com'));
      expect(vcf, contains('URL:https://sarah.dev'));
      expect(vcf, contains('ADR;TYPE=WORK:;;123 Market St, SF;;;;'));
      expect(vcf, contains('X-SOCIALPROFILE;TYPE=linkedin:https://linkedin.com/in/sarahchen'));
      expect(vcf, contains('NOTE:Met at TechConf 2026'));
      expect(vcf, contains('END:VCARD'));
    });

    test('builds a minimal vCard with only required fields', () {
      final vcf = NfcHceService.buildVCard(
        firstName: 'John',
        lastName: 'Doe',
      );

      expect(vcf, contains('BEGIN:VCARD'));
      expect(vcf, contains('N:Doe;John;;;'));
      expect(vcf, contains('FN:John Doe'));
      expect(vcf, contains('END:VCARD'));

      // Optional fields should NOT be present
      expect(vcf, isNot(contains('ORG:')));
      expect(vcf, isNot(contains('TITLE:')));
      expect(vcf, isNot(contains('TEL;')));
      expect(vcf, isNot(contains('EMAIL;')));
      expect(vcf, isNot(contains('URL:')));
      expect(vcf, isNot(contains('ADR;')));
      expect(vcf, isNot(contains('X-SOCIALPROFILE')));
      expect(vcf, isNot(contains('NOTE:')));
    });

    test('skips empty optional fields', () {
      final vcf = NfcHceService.buildVCard(
        firstName: 'Jane',
        lastName: 'Smith',
        email: '',
        phone: '',
        company: '',
        title: '',
      );

      expect(vcf, contains('FN:Jane Smith'));
      expect(vcf, isNot(contains('EMAIL;')));
      expect(vcf, isNot(contains('TEL;')));
      expect(vcf, isNot(contains('ORG:')));
      expect(vcf, isNot(contains('TITLE:')));
    });

    test('handles special characters in fields', () {
      final vcf = NfcHceService.buildVCard(
        firstName: "O'Brien",
        lastName: 'van der Berg',
        company: 'Acme & Co.',
        note: 'Discussed: pricing, "enterprise" tier',
      );

      expect(vcf, contains("FN:O'Brien van der Berg"));
      expect(vcf, contains('ORG:Acme & Co.'));
      expect(vcf, contains('NOTE:Discussed: pricing, "enterprise" tier'));
    });
  });
}
