import 'package:flutter_test/flutter_test.dart';
import 'package:pynp_app/features/reports/domain/entities/report_result.dart';

void main() {
  group('ReportResult', () {
    test('creates with required fields', () {
      const result = ReportResult(
        reportId: 'report-1',
        reportType: 'membership',
        content: {'totalMembers': 10, 'approved': 8},
      );
      expect(result.reportId, 'report-1');
      expect(result.reportType, 'membership');
      expect(result.content, {'totalMembers': 10, 'approved': 8});
    });
  });
}
