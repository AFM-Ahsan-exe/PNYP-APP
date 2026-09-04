import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/network/cloud_functions_client.dart';
import '../../domain/entities/report_result.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  Future<Map<String, dynamic>?> _callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user');
    final idToken = await user.getIdToken();
    final client = CloudFunctionsClient(
      projectId: Firebase.app().options.projectId,
      region: 'us-central1',
    );
    return client.call(functionName, data, idToken);
  }

  @override
  Future<ReportResult> generateReport({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, String>? filters,
  }) async {
    final result = await _callFunction('generateReport', {
      'reportType': reportType,
      'startDate': Timestamp.fromDate(startDate).toDate().toIso8601String(),
      'endDate': Timestamp.fromDate(endDate).toDate().toIso8601String(),
      'filters': filters,
    });

    final reportId = result?['reportId'] as String?;
    final reportContent = result?['reportContent'] as Map<String, dynamic>?;

    if (reportId == null || reportContent == null) {
      throw StateError('Failed to generate report');
    }

    return ReportResult(
      reportId: reportId,
      reportType: reportType,
      content: reportContent,
    );
  }
}