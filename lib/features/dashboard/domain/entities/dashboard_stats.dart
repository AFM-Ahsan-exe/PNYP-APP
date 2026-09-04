/// Aggregate counts shown on the admin dashboard overview.
class DashboardStats {
  final int totalMembers;
  final int totalVolunteers;
  final int totalCoordinators;
  final int pendingApplications;
  final int activeOpportunities;

  const DashboardStats({
    required this.totalMembers,
    required this.totalVolunteers,
    required this.totalCoordinators,
    required this.pendingApplications,
    required this.activeOpportunities,
  });

  const DashboardStats.empty()
    : totalMembers = 0,
      totalVolunteers = 0,
      totalCoordinators = 0,
      pendingApplications = 0,
      activeOpportunities = 0;

  int get totalPeople => totalMembers + totalVolunteers + totalCoordinators;

  bool get isAllZero =>
      totalMembers == 0 &&
      totalVolunteers == 0 &&
      totalCoordinators == 0 &&
      pendingApplications == 0 &&
      activeOpportunities == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DashboardStats &&
          other.totalMembers == totalMembers &&
          other.totalVolunteers == totalVolunteers &&
          other.totalCoordinators == totalCoordinators &&
          other.pendingApplications == pendingApplications &&
          other.activeOpportunities == activeOpportunities);

  @override
  int get hashCode => Object.hash(
    totalMembers,
    totalVolunteers,
    totalCoordinators,
    pendingApplications,
    activeOpportunities,
  );
}
