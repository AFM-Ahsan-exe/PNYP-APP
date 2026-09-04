import '../entities/analytics_aggregate.dart';
import '../entities/analytics_stats.dart';

abstract class AnalyticsRepository {
  Future<AnalyticsStats> getStats();
  Future<List<AnalyticsAggregate>> getAggregates({int limit = 30});
}
