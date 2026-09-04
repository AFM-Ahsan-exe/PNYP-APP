import 'package:flutter_test/flutter_test.dart';
import 'package:pynp_app/features/opportunities/domain/entities/opportunity.dart';

void main() {
  group('Opportunity', () {
    test('creates with required fields', () {
      final opportunity = Opportunity(
        id: 'opp-1',
        title: 'Test Opportunity',
        description: 'Description',
        organization: 'Org',
        location: 'Lahore',
        isRemote: false,
        applyUrl: 'https://example.com/apply',
        deadline: null,
        status: 'active',
      );
      expect(opportunity.id, 'opp-1');
      expect(opportunity.title, 'Test Opportunity');
      expect(opportunity.isRemote, isFalse);
      expect(opportunity.status, 'active');
    });

    test('copies with new values', () {
      final opportunity = Opportunity(
        id: 'opp-1',
        title: 'Test Opportunity',
        description: 'Description',
        organization: 'Org',
        location: 'Lahore',
        isRemote: false,
        applyUrl: 'https://example.com/apply',
        deadline: null,
        status: 'active',
        viewCount: 10,
        clickCount: 5,
        tags: ['education'],
        targetAudience: ['youth'],
        createdBy: 'user-1',
      );
      expect(opportunity.viewCount, 10);
      expect(opportunity.clickCount, 5);
      expect(opportunity.tags, ['education']);
      expect(opportunity.targetAudience, ['youth']);
      expect(opportunity.createdBy, 'user-1');
    });

    test('default values are correct', () {
      final opportunity = Opportunity(
        id: 'opp-1',
        title: 'Test',
        description: null,
        organization: null,
        location: null,
        isRemote: false,
        applyUrl: null,
        deadline: null,
        status: null,
      );
      expect(opportunity.isRemote, isFalse);
      expect(opportunity.description, isNull);
      expect(opportunity.organization, isNull);
      expect(opportunity.location, isNull);
      expect(opportunity.applyUrl, isNull);
      expect(opportunity.status, isNull);
    });
  });
}
