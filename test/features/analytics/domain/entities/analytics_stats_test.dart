import 'package:flutter_test/flutter_test.dart';
import 'package:pynp_app/features/analytics/domain/entities/analytics_stats.dart';

void main() {
  group('AnalyticsStats', () {
    test('creates with all fields', () {
      const stats = AnalyticsStats(
        totalUsers: 100,
        approvedMembers: 80,
        pendingMembers: 20,
        totalEvents: 10,
        totalDocuments: 5,
        totalNews: 3,
        totalVolunteers: 15,
        totalPayments: 8,
      );
      expect(stats.totalUsers, 100);
      expect(stats.approvedMembers, 80);
      expect(stats.pendingMembers, 20);
      expect(stats.totalEvents, 10);
      expect(stats.totalVolunteers, 15);
    });

    test('empty stats returns isAllZero true', () {
      const stats = AnalyticsStats.empty();
      expect(stats.isAllZero, isTrue);
    });

    test('non-empty stats returns isAllZero false', () {
      const stats = AnalyticsStats(
        totalUsers: 1,
        approvedMembers: 0,
        pendingMembers: 0,
        totalEvents: 0,
        totalDocuments: 0,
        totalNews: 0,
        totalVolunteers: 0,
        totalPayments: 0,
      );
      expect(stats.isAllZero, isFalse);
    });
  });
}
