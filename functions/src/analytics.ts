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
    const [
      usersCount,
      eventsCount,
      volunteersCount,
      paymentsCount,
      documentsCount,
      newsCount,
      activeMembersCount,
      pendingMembersCount,
    ] = await Promise.all([
      db.collection('users').count().get(),
      db.collection('events').count().get(),
      db.collection('volunteers').count().get(),
      db.collection('payments').count().get(),
      db.collection('documents').count().get(),
      db.collection('news').count().get(),
      db.collection('users').where('status', '==', 'approved').count().get(),
      db.collection('users').where('status', '==', 'pending').count().get(),
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
    };

    await db.collection('analytics_aggregates').doc(startOfDay.toISOString().split('T')[0]).set(aggregateData);

    return { message: 'Analytics aggregates computed', data: aggregateData };
  } catch (error) {
    functions.logger.error('computeAnalyticsAggregates error', error);
    return { message: 'Failed to compute analytics' };
  }
});
