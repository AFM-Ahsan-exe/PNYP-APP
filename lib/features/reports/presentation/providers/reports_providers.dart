import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/report_repository_impl.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/usecases/generate_report.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl();
});

final generateReportProvider = Provider<GenerateReport>((ref) {
  return GenerateReport(ref.watch(reportRepositoryProvider));
});
