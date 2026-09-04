class AnalyticsStats {
  final int totalUsers;
  final int approvedMembers;
  final int pendingMembers;
  final int totalEvents;
  final int totalDocuments;
  final int totalNews;
  final int totalVolunteers;
  final int totalPayments;

  const AnalyticsStats({
    required this.totalUsers,
    required this.approvedMembers,
    required this.pendingMembers,
    required this.totalEvents,
    required this.totalDocuments,
    required this.totalNews,
    required this.totalVolunteers,
    required this.totalPayments,
  });

  const AnalyticsStats.empty()
    : totalUsers = 0,
      approvedMembers = 0,
      pendingMembers = 0,
      totalEvents = 0,
      totalDocuments = 0,
      totalNews = 0,
      totalVolunteers = 0,
      totalPayments = 0;

  bool get isAllZero =>
      totalUsers == 0 &&
      approvedMembers == 0 &&
      pendingMembers == 0 &&
      totalEvents == 0 &&
      totalDocuments == 0 &&
      totalNews == 0 &&
      totalVolunteers == 0 &&
      totalPayments == 0;
}
