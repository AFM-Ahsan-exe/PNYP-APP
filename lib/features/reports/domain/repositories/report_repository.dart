import '../entities/report_result.dart';

abstract class ReportRepository {
  Future<ReportResult> generateReport({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, String>? filters,
  });
}
