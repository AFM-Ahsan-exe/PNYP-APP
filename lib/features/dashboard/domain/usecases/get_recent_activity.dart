import '../entities/activity_item.dart';
import '../repositories/dashboard_repository.dart';

class GetRecentActivity {
  final DashboardRepository _repository;

  const GetRecentActivity(this._repository);

  Future<List<ActivityItem>> call({int limit = 10}) =>
      _repository.getRecentActivity(limit: limit);
}
