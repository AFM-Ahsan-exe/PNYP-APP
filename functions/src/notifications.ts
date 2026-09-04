import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { isAtLeastRole } from './helpers';

const db = admin.firestore();
const auth = admin.auth();

async function sendFcmMessage(
  token: string,
  notification: { title: string; body: string },
  data?: Record<string, string>,
) {
  if (!token) return;

  try {
    await admin.messaging().send({
      token,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: data || {},
      android: {
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    });
  } catch (error) {
    functions.logger.error('FCM send error', error);
  }
}

async function isNotificationEnabled(
  userId: string,
  category: string,
): Promise<boolean> {
  const userDoc = await db.collection('users').doc(userId).get();

  const preferences =
    userDoc.data()?.notificationPreferences as
      | Record<string, boolean>
      | undefined;

  if (!preferences) return true;

  return preferences[category] !== false;
}

export const onUserCreated =
  functions.auth.user().onCreate(async (user) => {
    try {
      const notificationRef =
        db.collection('notifications').doc();

      await notificationRef.set({
        recipientId: user.uid,
        title: 'Welcome to PYNP',
        body:
          'Your registration has been received. Please verify your email and wait for administrator approval.',
        type: 'welcome',
        category: 'system',
        isRead: false,
        timestamp: admin.firestore.Timestamp.now(),
      });

      const userDoc =
        await db.collection('users').doc(user.uid).get();

      const fcmToken =
        userDoc.data()?.fcmToken as string | undefined;

      if (fcmToken) {
        await sendFcmMessage(
          fcmToken,
          {
            title: 'Welcome to PYNP',
            body: 'Your registration has been received.',
          },
          {
            notificationId: notificationRef.id,
            type: 'welcome',
          },
        );
      }

      functions.logger.info(
        'Verification email queued for',
        user.email,
      );
    } catch (error) {
      functions.logger.error(
        'onUserCreated error',
        error,
      );
    }
  });

export const onMembershipApproved =
  functions.firestore
    .document('users/{userId}')
    .onUpdate(async (snap, context) => {
      try {
        const newData = snap.after.data();
        const previousData = snap.before.data();

        if (
          previousData?.status === 'pending' &&
          newData?.status === 'approved'
        ) {
          const userId = context.params.userId;
          const user = await auth.getUser(userId);

          const notificationRef =
            db.collection('notifications').doc();

          await notificationRef.set({
            recipientId: userId,
            title: 'Membership Approved',
            body:
              'Congratulations! Your PYNP membership has been approved. Welcome aboard!',
            type: 'approval',
            category: 'system',
            isRead: false,
            timestamp: admin.firestore.Timestamp.now(),
          });

          const fcmToken =
            newData?.fcmToken as string | undefined;

          if (fcmToken) {
            await sendFcmMessage(
              fcmToken,
              {
                title: 'Membership Approved',
                body:
                  'Congratulations! Your PYNP membership has been approved.',
              },
              {
                notificationId: notificationRef.id,
                type: 'approval',
              },
            );
          }

          functions.logger.info(
            'Approval notification sent to',
            user.email,
          );
        }
      } catch (error) {
        functions.logger.error(
          'onMembershipApproved error',
          error,
        );
      }
    });

export const onMembershipRejected =
  functions.firestore
    .document('users/{userId}')
    .onUpdate(async (snap, context) => {
      try {
        const newData = snap.after.data();
        const previousData = snap.before.data();

        if (
          previousData?.status === 'pending' &&
          newData?.status === 'rejected'
        ) {
          const userId = context.params.userId;
          const user = await auth.getUser(userId);

          const reason =
            newData?.rejectionReason ||
            'No reason provided';

          const notificationRef =
            db.collection('notifications').doc();

          await notificationRef.set({
            recipientId: userId,
            title: 'Membership Application Update',
            body:
              `Your membership application was not approved. Reason: ${reason}`,
            type: 'rejection',
            category: 'system',
            isRead: false,
            timestamp: admin.firestore.Timestamp.now(),
          });

          const fcmToken =
            newData?.fcmToken as string | undefined;

          if (fcmToken) {
            await sendFcmMessage(
              fcmToken,
              {
                title: 'Membership Application Update',
                body:
                  `Your membership application was not approved. Reason: ${reason}`,
              },
              {
                notificationId: notificationRef.id,
                type: 'rejection',
              },
            );
          }

          functions.logger.info(
            'Rejection notification sent to',
            user.email,
          );
        }
      } catch (error) {
        functions.logger.error(
          'onMembershipRejected error',
          error,
        );
      }
    });

export const onRenewalSubmitted =
  functions.firestore
    .document('payments/{paymentId}')
    .onCreate(async (snap, _context) => {
      try {
        const data = snap.data();

        if (
          data?.paymentType !== 'membership_renewal' ||
          data?.status !== 'pending'
        ) {
          return;
        }

        const userId = data.userId as string;
        const user = await auth.getUser(userId);

        const enabled =
          await isNotificationEnabled(
            userId,
            'payments',
          );

        if (!enabled) return;

        const notificationRef =
          db.collection('notifications').doc();

        await notificationRef.set({
          recipientId: userId,
          title: 'Renewal Submitted',
          body:
            'Your membership renewal request has been submitted for review.',
          type: 'renewal',
          category: 'payments',
          isRead: false,
          timestamp: admin.firestore.Timestamp.now(),
        });

        const userDoc =
          await db.collection('users').doc(userId).get();

        const fcmToken =
          userDoc.data()?.fcmToken as string | undefined;

        if (fcmToken) {
          await sendFcmMessage(
            fcmToken,
            {
              title: 'Renewal Submitted',
              body:
                'Your membership renewal request has been submitted for review.',
            },
            {
              notificationId: notificationRef.id,
              type: 'renewal',
            },
          );
        }

        functions.logger.info(
          'Renewal submission notification sent to',
          user.email,
        );
      } catch (error) {
        functions.logger.error(
          'onRenewalSubmitted error',
          error,
        );
      }
    });

export const sendNotification =
  functions.https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication required',
        );
      }

      const callerToken =
        await auth.getUser(context.auth.uid);

      const callerClaims =
        callerToken.customClaims || {};

      // TASK 29:
      // Only national administrators and higher roles
      // can send broadcast/targeted notifications.
      if (
        !isAtLeastRole(
          'national_admin',
          callerClaims,
        )
      ) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only national administrators and above can send notifications',
        );
      }

      const {
        recipientId,
        recipientEmail,
        title,
        body,
        type = 'broadcast',
      } = data as {
        recipientId?: string;
        recipientEmail?: string;
        title: string;
        body: string;
        type?: string;
      };

      if (!title || !body) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'title and body are required',
        );
      }

      // Resolve recipient email to a real Firebase UID.
      let resolvedRecipientId = recipientId;

      if (!resolvedRecipientId && recipientEmail) {
        try {
          const userRecord =
            await auth.getUserByEmail(
              recipientEmail.trim(),
            );

          resolvedRecipientId = userRecord.uid;
        } catch (error) {
          throw new functions.https.HttpsError(
            'not-found',
            `No user found with email "${recipientEmail}"`,
          );
        }
      }

      const targetIds =
        resolvedRecipientId != null
          ? [resolvedRecipientId]
          : null;

      let recipientUids = targetIds;

      if (recipientUids == null) {
        const usersSnapshot =
          await db.collection('users').get();

        recipientUids =
          usersSnapshot.docs.map(
            (doc) => doc.id,
          );
      }

      const notificationPromises =
        recipientUids.map(async (uid) => {
          const notificationRef =
            db.collection('notifications').doc();

          await notificationRef.set({
            recipientId: uid,
            title,
            body,
            type,
            category: 'system',
            isRead: false,
            timestamp:
              admin.firestore.Timestamp.now(),
          });

          const userDoc =
            await db
              .collection('users')
              .doc(uid)
              .get();

          const fcmToken =
            userDoc.data()?.fcmToken as
              | string
              | undefined;

          if (fcmToken) {
            await sendFcmMessage(
              fcmToken,
              {
                title,
                body,
              },
              {
                notificationId:
                  notificationRef.id,
                type,
              },
            );
          }
        });

      await Promise.all(
        notificationPromises,
      );

      return {
        message:
          'Notification sent successfully',
        recipientCount:
          recipientUids.length,
      };
    } catch (error) {
      functions.logger.error(
        'sendNotification error',
        error,
      );

      if (
        error instanceof
        functions.https.HttpsError
      ) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to send notification',
      );
    }
  });

export const onVolunteerStatusChanged =
  functions.firestore
    .document('volunteers/{volunteerId}')
    .onUpdate(async (snap, _context) => {
      try {
        const newData = snap.after.data();
        const previousData = snap.before.data();

        const previousStatus =
          previousData?.status as
            | string
            | undefined;

        const newStatus =
          newData?.status as
            | string
            | undefined;

        if (
          previousStatus === 'pending' &&
          (
            newStatus === 'accepted' ||
            newStatus === 'rejected'
          )
        ) {
          const userId =
            newData?.userId as
              | string
              | undefined;

          if (!userId) return;

          const enabled =
            await isNotificationEnabled(
              userId,
              'volunteers',
            );

          if (!enabled) return;

          const user =
            await auth.getUser(userId);

          const title =
            newStatus === 'accepted'
              ? 'Volunteer Application Accepted'
              : 'Volunteer Application Update';

          const body =
            newStatus === 'accepted'
              ? 'Your volunteer application has been accepted. Welcome aboard!'
              : 'Your volunteer application was not approved.';

          const notificationRef =
            db.collection('notifications').doc();

          await notificationRef.set({
            recipientId: userId,
            title,
            body,
            type: 'volunteer',
            category: 'volunteers',
            isRead: false,
            timestamp:
              admin.firestore.Timestamp.now(),
          });

          const userDoc =
            await db
              .collection('users')
              .doc(userId)
              .get();

          const fcmToken =
            userDoc.data()?.fcmToken as
              | string
              | undefined;

          if (fcmToken) {
            await sendFcmMessage(
              fcmToken,
              {
                title,
                body,
              },
              {
                notificationId:
                  notificationRef.id,
                type: 'volunteer',
              },
            );
          }

          functions.logger.info(
            'Volunteer status notification sent to',
            user.email,
          );
        }
      } catch (error) {
        functions.logger.error(
          'onVolunteerStatusChanged error',
          error,
        );
      }
    });

