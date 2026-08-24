import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

function isAtLeastRole(minimumRole: string, claims: Record<string, unknown>): boolean {
  const role = claims.role as string | undefined;
  if (!role) return false;
  const hierarchy = ['member', 'district_coordinator', 'regional_coordinator', 'content_manager', 'opportunity_manager', 'national_admin', 'president', 'super_admin'];
  const callerIndex = hierarchy.indexOf(role);
  const requiredIndex = hierarchy.indexOf(minimumRole);
  return callerIndex >= requiredIndex;
}

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
      startDate: admin.firestore.Timestamp;
      endDate: admin.firestore.Timestamp;
      filters?: Record<string, string>;
    };

    if (!reportType || !startDate || !endDate) {
      throw new functions.https.HttpsError('invalid-argument', 'reportType, startDate, and endDate are required');
    }

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
      case 'membership':
        const membersSnapshot = await db.collection('users')
          .where('createdAt', '>=', startDate)
          .where('createdAt', '<=', endDate)
          .get();
        reportContent = {
          totalMembers: membersSnapshot.size,
          approved: membersSnapshot.docs.filter((doc) => doc.data().status === 'approved').length,
          pending: membersSnapshot.docs.filter((doc) => doc.data().status === 'pending').length,
          rejected: membersSnapshot.docs.filter((doc) => doc.data().status === 'rejected').length,
        };
        break;

      case 'events':
        const eventsSnapshot = await db.collection('events')
          .where('createdAt', '>=', startDate)
          .where('createdAt', '<=', endDate)
          .get();
        const totalRegistrations = await db.collection('event_registrations')
          .where('registeredAt', '>=', startDate)
          .where('registeredAt', '<=', endDate)
          .get();
        reportContent = {
          totalEvents: eventsSnapshot.size,
          totalRegistrations: totalRegistrations.size,
          events: eventsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
        };
        break;

      case 'volunteers':
        const volunteersSnapshot = await db.collection('volunteers')
          .where('appliedAt', '>=', startDate)
          .where('appliedAt', '<=', endDate)
          .get();
        reportContent = {
          totalApplications: volunteersSnapshot.size,
          accepted: volunteersSnapshot.docs.filter((doc) => doc.data().status === 'accepted').length,
          rejected: volunteersSnapshot.docs.filter((doc) => doc.data().status === 'rejected').length,
          pending: volunteersSnapshot.docs.filter((doc) => doc.data().status === 'pending').length,
        };
        break;

      case 'payments':
        const paymentsSnapshot = await db.collection('payments')
          .where('createdAt', '>=', startDate)
          .where('createdAt', '<=', endDate)
          .get();
        const totalAmount = paymentsSnapshot.docs.reduce((sum, doc) => sum + ((doc.data().amount as number) || 0), 0);
        reportContent = {
          totalPayments: paymentsSnapshot.size,
          totalAmount,
          verified: paymentsSnapshot.docs.filter((doc) => doc.data().status === 'verified').length,
          pending: paymentsSnapshot.docs.filter((doc) => doc.data().status === 'pending').length,
        };
        break;

      case 'engagement':
        const notificationsSent = await db.collection('notifications')
          .where('timestamp', '>=', startDate)
          .where('timestamp', '<=', endDate)
          .get();
        const newsPublished = await db.collection('news')
          .where('publishedAt', '>=', startDate)
          .where('publishedAt', '<=', endDate)
          .get();
        reportContent = {
          notificationsSent: notificationsSent.size,
          newsArticles: newsPublished.size,
        };
        break;

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
      afterValue: { reportType, startDate, endDate },
      timestamp: now,
    });

    return { reportId: reportRef.id, reportContent };
  } catch (error) {
    functions.logger.error('generateReport error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to generate report');
  }
});
