class ReportResult {
  final String reportId;
  final String reportType;
  final Map<String, dynamic> content;

  const ReportResult({
    required this.reportId,
    required this.reportType,
    required this.content,
  });
}
