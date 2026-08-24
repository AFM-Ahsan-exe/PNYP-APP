import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

export const computeAnalyticsAggregates = functions.pubsub.schedule('0 0 * * *').onRun(async (context) => {
  try {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startTimestamp = admin.firestore.Timestamp.fromDate(startOfDay);

    const usersSnapshot = await db.collection('users').get();
    const eventsSnapshot = await db.collection('events').get();
    const volunteersSnapshot = await db.collection('volunteers').get();
    const paymentsSnapshot = await db.collection('payments').get();
    const documentsSnapshot = await db.collection('documents').get();
    const newsSnapshot = await db.collection('news').get();

    const aggregateData = {
      date: startTimestamp,
      totalUsers: usersSnapshot.size,
      totalEvents: eventsSnapshot.size,
      totalVolunteers: volunteersSnapshot.size,
      totalPayments: paymentsSnapshot.size,
      totalDocuments: documentsSnapshot.size,
      totalNews: newsSnapshot.size,
      activeMembers: usersSnapshot.docs.filter((doc) => doc.data().status === 'approved').length,
      pendingMembers: usersSnapshot.docs.filter((doc) => doc.data().status === 'pending').length,
    };

    await db.collection('analytics_aggregates').doc(startOfDay.toISOString().split('T')[0]).set(aggregateData);

    return { message: 'Analytics aggregates computed', data: aggregateData };
  } catch (error) {
    functions.logger.error('computeAnalyticsAggregates error', error);
    return { message: 'Failed to compute analytics' };
  }
});
