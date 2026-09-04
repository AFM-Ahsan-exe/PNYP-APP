import '../../domain/entities/analytics_stats.dart';
import '../../domain/repositories/analytics_repository.dart';

class GetAnalyticsStats {
  final AnalyticsRepository repository;
  GetAnalyticsStats(this.repository);

  Future<AnalyticsStats> call() => repository.getStats();
}
