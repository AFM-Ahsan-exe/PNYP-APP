import '../../domain/entities/analytics_aggregate.dart';
import '../../domain/repositories/analytics_repository.dart';

class GetAnalyticsAggregates {
  final AnalyticsRepository repository;
  GetAnalyticsAggregates(this.repository);

  Future<List<AnalyticsAggregate>> call({int limit = 30}) =>
      repository.getAggregates(limit: limit);
}
