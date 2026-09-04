import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const computeAnalyticsAggregates = functions.pubsub.schedule('0 0 * * *').onRun(async (_context) => {
  try {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startTimestamp = admin.firestore.Timestamp.fromDate(startOfDay);

    // This runs daily, so the cost of full collection scans here is much
    // lower-frequency than the on-demand dashboard stats call was, but
    // it's still needlessly downloading every document just to count
    // them. Switched to count() aggregation queries for the same reason
    // as getDashboardStats.
    const coordinatorRoles = [
      'admin',
      'district_coordinator',
      'regional_coordinator',
      'content_manager',
      'opportunity_manager',
      'national_admin',
      'president',
      'super_admin',
    ];

    const [
      usersCount,
      eventsCount,
      volunteersCount,
      paymentsCount,
      documentsCount,
      newsCount,
      activeMembersCount,
      pendingMembersCount,
      // Same shape as getDashboardStats, so stat-card trends compare
      // like-for-like against this daily snapshot.
      totalMembersCount,
      pendingApplicationsCount,
      totalCoordinatorsCount,
      activeOpportunitiesCount,
    ] = await Promise.all([
      db.collection('users').count().get(),
      db.collection('events').count().get(),
      db.collection('volunteers').count().get(),
      db.collection('payments').count().get(),
      db.collection('documents').count().get(),
      db.collection('news').count().get(),
      db.collection('users').where('status', '==', 'approved').count().get(),
      db.collection('users').where('status', '==', 'pending').count().get(),
      db.collection('users').where('role', '==', 'member').count().get(),
      db.collection('users').where('role', '==', 'member').where('status', '==', 'pending').count().get(),
      db.collection('users').where('role', 'in', coordinatorRoles).count().get(),
      db.collection('opportunities').where('status', '==', 'active').count().get(),
    ]);

    const aggregateData = {
      date: startTimestamp,
      totalUsers: usersCount.data().count,
      totalEvents: eventsCount.data().count,
      totalVolunteers: volunteersCount.data().count,
      totalPayments: paymentsCount.data().count,
      totalDocuments: documentsCount.data().count,
      totalNews: newsCount.data().count,
      activeMembers: activeMembersCount.data().count,
      pendingMembers: pendingMembersCount.data().count,
      totalMembers: totalMembersCount.data().count,
      pendingApplications: pendingApplicationsCount.data().count,
      totalCoordinators: totalCoordinatorsCount.data().count,
      activeOpportunities: activeOpportunitiesCount.data().count,
    };

    await db.collection('analytics_aggregates').doc(startOfDay.toISOString().split('T')[0]).set(aggregateData);

    return { message: 'Analytics aggregates computed', data: aggregateData };
  } catch (error) {
    functions.logger.error('computeAnalyticsAggregates error', error);
    return { message: 'Failed to compute analytics' };
  }
});