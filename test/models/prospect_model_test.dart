import 'package:flutter_test/flutter_test.dart';
import 'package:bump/data/models/prospect_model.dart';

void main() {
  group('Prospect', () {
    final sampleJson = {
      'id': 'abc-123',
      'user_id': 'user-1',
      'event_id': 'event-1',
      'exchanged_with': 'user-2',
      'first_name': 'Sarah',
      'last_name': 'Chen',
      'email': 'sarah@example.com',
      'phone': '+1234567890',
      'company': 'Stripe',
      'title': 'Engineering Manager',
      'avatar_url': 'https://example.com/avatar.jpg',
      'linkedin': 'https://linkedin.com/in/sarahchen',
      'notes': 'Met at TechConf, interested in API design',
      'status': 'new',
      'exchange_method': 'nfc',
      'exchange_time': '2026-03-26T12:00:00.000Z',
      'tags': ['conference', 'engineering'],
      'exchange_type': 'mutual_bump',
      'enrichment_status': 'complete',
      'missing_fields': <String>[],
      'exchange_direction': 'mutual',
    };

    test('fromJson creates a valid Prospect with all fields', () {
      final prospect = Prospect.fromJson(sampleJson);

      expect(prospect.id, 'abc-123');
      expect(prospect.firstName, 'Sarah');
      expect(prospect.lastName, 'Chen');
      expect(prospect.email, 'sarah@example.com');
      expect(prospect.phone, '+1234567890');
      expect(prospect.company, 'Stripe');
      expect(prospect.title, 'Engineering Manager');
      expect(prospect.linkedIn, 'https://linkedin.com/in/sarahchen');
      expect(prospect.status, ProspectStatus.newProspect);
      expect(prospect.exchangeMethod, ExchangeMethod.nfc);
      expect(prospect.tags, ['conference', 'engineering']);
      expect(prospect.exchangeDirection, 'mutual');
    });

    test('fromJson handles missing optional fields gracefully', () {
      final minimalJson = {
        'id': 'abc-123',
        'exchange_time': '2026-03-26T12:00:00.000Z',
      };

      final prospect = Prospect.fromJson(minimalJson);

      expect(prospect.id, 'abc-123');
      expect(prospect.firstName, '');
      expect(prospect.lastName, '');
      expect(prospect.email, '');
      expect(prospect.phone, '');
      expect(prospect.company, '');
      expect(prospect.title, '');
      expect(prospect.linkedIn, isNull);
      expect(prospect.avatar, isNull);
      expect(prospect.eventId, '');
      expect(prospect.status, ProspectStatus.newProspect);
      expect(prospect.exchangeMethod, ExchangeMethod.bump);
      expect(prospect.tags, isEmpty);
    });

    test('toJson/fromJson roundtrip preserves all data', () {
      final original = Prospect.fromJson(sampleJson);
      final json = original.toJson();
      final restored = Prospect.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.firstName, original.firstName);
      expect(restored.lastName, original.lastName);
      expect(restored.email, original.email);
      expect(restored.phone, original.phone);
      expect(restored.company, original.company);
      expect(restored.title, original.title);
      expect(restored.linkedIn, original.linkedIn);
      expect(restored.status, original.status);
      expect(restored.exchangeMethod, original.exchangeMethod);
      expect(restored.tags, original.tags);
    });

    test('fullName combines first and last name', () {
      final prospect = Prospect.fromJson(sampleJson);
      expect(prospect.fullName, 'Sarah Chen');
    });

    test('initials returns uppercase first letters', () {
      final prospect = Prospect.fromJson(sampleJson);
      expect(prospect.initials, 'SC');
    });

    test('completenessScore is 1.0 when all fields present', () {
      final prospect = Prospect.fromJson(sampleJson);
      expect(prospect.completenessScore, 1.0);
    });

    test('completenessScore is 0.0 when all fields empty', () {
      final prospect = Prospect.fromJson({
        'id': 'abc',
        'exchange_time': '2026-03-26T12:00:00.000Z',
      });
      expect(prospect.completenessScore, 0.0);
    });

    test('isPartial returns true when enrichment is not complete', () {
      final prospect = Prospect.fromJson({
        ...sampleJson,
        'enrichment_status': 'partial',
      });
      expect(prospect.isPartial, true);
    });
  });

  group('ProspectStatus', () {
    test('fromString parses known statuses', () {
      expect(ProspectStatusX.fromString('new'), ProspectStatus.newProspect);
      expect(ProspectStatusX.fromString('contacted'), ProspectStatus.contacted);
      expect(ProspectStatusX.fromString('interested'), ProspectStatus.interested);
      expect(ProspectStatusX.fromString('converted'), ProspectStatus.converted);
      expect(ProspectStatusX.fromString('archived'), ProspectStatus.archived);
    });

    test('fromString defaults to newProspect for unknown values', () {
      expect(ProspectStatusX.fromString('unknown'), ProspectStatus.newProspect);
      expect(ProspectStatusX.fromString(''), ProspectStatus.newProspect);
    });

    test('label roundtrips with fromString', () {
      for (final status in ProspectStatus.values) {
        expect(ProspectStatusX.fromString(status.label), status);
      }
    });
  });

  group('ExchangeMethod', () {
    test('fromString parses known methods', () {
      expect(ExchangeMethodX.fromString('bump'), ExchangeMethod.bump);
      expect(ExchangeMethodX.fromString('qr'), ExchangeMethod.qr);
      expect(ExchangeMethodX.fromString('nfc'), ExchangeMethod.nfc);
      expect(ExchangeMethodX.fromString('link'), ExchangeMethod.link);
      expect(ExchangeMethodX.fromString('quick_capture'), ExchangeMethod.quickCapture);
    });

    test('fromString defaults to bump for unknown values', () {
      expect(ExchangeMethodX.fromString('unknown'), ExchangeMethod.bump);
      expect(ExchangeMethodX.fromString(''), ExchangeMethod.bump);
    });

    test('label roundtrips with fromString', () {
      for (final method in ExchangeMethod.values) {
        expect(ExchangeMethodX.fromString(method.label), method);
      }
    });
  });
}
