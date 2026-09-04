import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardStats {
  final DashboardRepository _repository;

  const GetDashboardStats(this._repository);

  Future<DashboardStats> call() => _repository.getStats();
}
