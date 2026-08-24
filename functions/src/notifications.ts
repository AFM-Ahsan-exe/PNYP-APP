import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  try {
    await db.collection('notifications').add({
      recipientId: user.uid,
      title: 'Welcome to PYNP',
      body: 'Your registration has been received. Please verify your email and wait for administrator approval.',
      type: 'welcome',
      isRead: false,
      timestamp: admin.firestore.Timestamp.now(),
    });

    functions.logger.info('Verification email queued for', user.email);
  } catch (error) {
    functions.logger.error('onUserCreated error', error);
  }
});

export const onMembershipApproved = functions.firestore.document('users/{userId}').onUpdate(async (snap, context) => {
  try {
    const newData = snap.after.data();
    const previousData = snap.before.data();

    if (previousData?.status === 'pending' && newData?.status === 'approved') {
      const userId = context.params.userId;
      const user = await auth.getUser(userId);

      await db.collection('notifications').add({
        recipientId: userId,
        title: 'Membership Approved',
        body: 'Congratulations! Your PYNP membership has been approved. Welcome aboard!',
        type: 'approval',
        isRead: false,
        timestamp: admin.firestore.Timestamp.now(),
      });

      functions.logger.info('Approval notification sent to', user.email);
    }
  } catch (error) {
    functions.logger.error('onMembershipApproved error', error);
  }
});

export const onMembershipRejected = functions.firestore.document('users/{userId}').onUpdate(async (snap, context) => {
  try {
    const newData = snap.after.data();
    const previousData = snap.before.data();

    if (previousData?.status === 'pending' && newData?.status === 'rejected') {
      const userId = context.params.userId;
      const user = await auth.getUser(userId);
      const reason = newData?.rejectionReason || 'No reason provided';

      await db.collection('notifications').add({
        recipientId: userId,
        title: 'Membership Application Update',
        body: `Your membership application was not approved. Reason: ${reason}`,
        type: 'rejection',
        isRead: false,
        timestamp: admin.firestore.Timestamp.now(),
      });

      functions.logger.info('Rejection notification sent to', user.email);
    }
  } catch (error) {
    functions.logger.error('onMembershipRejected error', error);
  }
});

export const sendNotification = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }

    const callerToken = await auth.getUser(context.auth.uid);
    const callerClaims = callerToken.customClaims || {};
    if (callerClaims.admin !== true && callerClaims.role !== 'national_admin' && callerClaims.role !== 'president' && callerClaims.role !== 'super_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only administrators can send notifications');
    }

    const { recipientId, title, body, type = 'broadcast' } = data as {
      recipientId?: string;
      title: string;
      body: string;
      type?: string;
    };

    if (!title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'title and body are required');
    }

    const targetIds = recipientId != null ? [recipientId] : null;
    let recipientUids = targetIds;

    if (recipientUids == null) {
      const usersSnapshot = await db.collection('users').get();
      recipientUids = usersSnapshot.docs.map((doc) => doc.id);
    }

    const notificationPromises = recipientUids.map((uid) =>
      db.collection('notifications').add({
        recipientId: uid,
        title,
        body,
        type,
        isRead: false,
        timestamp: admin.firestore.Timestamp.now(),
      })
    );

    await Promise.all(notificationPromises);

    return {
      message: 'Notification sent successfully',
      recipientCount: recipientUids.length,
    };
  } catch (error) {
    functions.logger.error('sendNotification error', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});
