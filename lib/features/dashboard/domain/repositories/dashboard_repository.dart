import '../entities/activity_item.dart';
import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<DashboardStats> getStats();

  Future<List<ActivityItem>> getRecentActivity({int limit = 10});
}
