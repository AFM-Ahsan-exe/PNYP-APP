import '../../domain/entities/report_result.dart';
import '../../domain/repositories/report_repository.dart';

class GenerateReport {
  final ReportRepository repository;
  GenerateReport(this.repository);

  Future<ReportResult> call({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, String>? filters,
  }) => repository.generateReport(
    reportType: reportType,
    startDate: startDate,
    endDate: endDate,
    filters: filters,
  );
}
