class GrowthPoint {
  final DateTime date;
  final int totalUsers;
  final int totalMembers;
  final int totalVolunteers;
  final int totalCoordinators;
  final int pendingApplications;
  final int activeOpportunities;

  const GrowthPoint({
    required this.date,
    required this.totalUsers,
    required this.totalMembers,
    required this.totalVolunteers,
    required this.totalCoordinators,
    required this.pendingApplications,
    required this.activeOpportunities,
  });
}