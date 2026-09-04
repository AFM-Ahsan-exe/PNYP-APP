import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { isAtLeastRole } from './helpers';

const db = admin.firestore();
const auth = admin.auth();

export const generateReport = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('regional_coordinator', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only regional coordinators and above can generate reports');
    }

    const { reportType, startDate, endDate, filters } = data as {
      reportType: 'membership' | 'events' | 'volunteers' | 'payments' | 'engagement';
      startDate: admin.firestore.Timestamp | string;
      endDate: admin.firestore.Timestamp | string;
      filters?: Record<string, string>;
    };

    if (!reportType || !startDate || !endDate) {
      throw new functions.https.HttpsError('invalid-argument', 'reportType, startDate, and endDate are required');
    }

    const toTimestamp = (value: admin.firestore.Timestamp | string): admin.firestore.Timestamp => {
      if (value instanceof admin.firestore.Timestamp) return value;
      return admin.firestore.Timestamp.fromDate(new Date(value as string));
    };

    const start = toTimestamp(startDate);
    const end = toTimestamp(endDate);

    const now = admin.firestore.Timestamp.now();
    const reportRef = db.collection('reports').doc();
    const reportData = {
      id: reportRef.id,
      reportType,
      startDate,
      endDate,
      filters: filters || {},
      generatedBy: context.auth.uid,
      generatedAt: now,
      status: 'processing',
    };

    await reportRef.set(reportData);

    let reportContent: Record<string, unknown> = {};

    switch (reportType) {
      case 'membership': {
        const membersSnapshot = await db.collection('users')
          .where('createdAt', '>=', start)
          .where('createdAt', '<=', end)
          .get();
        reportContent = {
          totalMembers: membersSnapshot.size,
          approved: membersSnapshot.docs.filter((doc) => doc.data().status === 'approved').length,
          pending: membersSnapshot.docs.filter((doc) => doc.data().status === 'pending').length,
          rejected: membersSnapshot.docs.filter((doc) => doc.data().status === 'rejected').length,
        };
        break;
      }

      case 'events': {
        const eventsSnapshot = await db.collection('events')
          .where('createdAt', '>=', start)
          .where('createdAt', '<=', end)
          .get();
        const totalRegistrations = await db.collection('event_registrations')
          .where('registeredAt', '>=', start)
          .where('registeredAt', '<=', end)
          .get();
        reportContent = {
          totalEvents: eventsSnapshot.size,
          totalRegistrations: totalRegistrations.size,
          events: eventsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
        };
        break;
      }

      case 'volunteers': {
        const volunteersSnapshot = await db.collection('volunteers')
          .where('appliedAt', '>=', start)
          .where('appliedAt', '<=', end)
          .get();
        reportContent = {
          totalApplications: volunteersSnapshot.size,
          accepted: volunteersSnapshot.docs.filter((doc) => doc.data().status === 'accepted').length,
          rejected: volunteersSnapshot.docs.filter((doc) => doc.data().status === 'rejected').length,
          pending: volunteersSnapshot.docs.filter((doc) => doc.data().status === 'pending').length,
        };
        break;
      }

      case 'payments': {
        const paymentsSnapshot = await db.collection('payments')
          .where('createdAt', '>=', start)
          .where('createdAt', '<=', end)
          .get();
        const totalAmount = paymentsSnapshot.docs.reduce((sum, doc) => sum + ((doc.data().amount as number) || 0), 0);
        reportContent = {
          totalPayments: paymentsSnapshot.size,
          totalAmount,
          verified: paymentsSnapshot.docs.filter((doc) => doc.data().status === 'verified').length,
          pending: paymentsSnapshot.docs.filter((doc) => doc.data().status === 'pending').length,
        };
        break;
      }

      case 'engagement': {
        const notificationsSent = await db.collection('notifications')
          .where('timestamp', '>=', start)
          .where('timestamp', '<=', end)
          .get();
        const newsPublished = await db.collection('news')
          .where('publishedAt', '>=', start)
          .where('publishedAt', '<=', end)
          .get();
        reportContent = {
          notificationsSent: notificationsSent.size,
          newsArticles: newsPublished.size,
        };
        break;
      }

      default:
        throw new functions.https.HttpsError('invalid-argument', 'Invalid reportType');
    }

    await reportRef.update({
      status: 'completed',
      completedAt: admin.firestore.Timestamp.now(),
      content: reportContent,
    });

    await db.collection('audit_logs').add({
      actionType: 'READ',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'reports',
      targetDocumentId: reportRef.id,
      beforeValue: null,
      afterValue: { reportType, startDate: start, endDate: end },
      timestamp: now,
    });

    return { reportId: reportRef.id, reportContent };
  } catch (error) {
    functions.logger.error('generateReport error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to generate report');
  }
});

export const getReportHistory = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('regional_coordinator', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only regional coordinators and above can view report history');
    }

    const snapshot = await db.collection('reports')
      .orderBy('generatedAt', 'desc')
      .limit(50)
      .get();

    const reports = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return { reports };
  } catch (error) {
    functions.logger.error('getReportHistory error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to load report history');
  }
});
