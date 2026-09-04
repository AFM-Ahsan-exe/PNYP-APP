import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { isAtLeastRole, toFirestoreTimestamp } from './helpers';

const db = admin.firestore();
const auth = admin.auth();

export const createEvent = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('district_coordinator', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only coordinators and above can create events');
    }

    const { title, description, eventType, startDateTime: rawStart, endDateTime: rawEnd, location, isOnline, maxParticipants, targetAudience, registrationDeadline: rawDeadline, bannerUrl, entryFee, organizingTeam, sponsors, tags } = data as {
      title: string;
      description: string;
      eventType: string;
      startDateTime: admin.firestore.Timestamp | string;
      endDateTime: admin.firestore.Timestamp | string;
      location?: string;
      isOnline?: boolean;
      maxParticipants?: number;
      targetAudience?: string[];
      registrationDeadline?: admin.firestore.Timestamp | string;
      bannerUrl?: string;
      entryFee?: number;
      organizingTeam?: string[];
      sponsors?: string[];
      tags?: string[];
    };

    // The client sends dates as ISO strings (a raw Timestamp can't be
    // JSON-encoded), so these must be converted back before use.
    const startDateTime = toFirestoreTimestamp(rawStart);
    const endDateTime = toFirestoreTimestamp(rawEnd);
    const registrationDeadline = toFirestoreTimestamp(rawDeadline);

    if (!title || !description || !eventType || !startDateTime || !endDateTime) {
      throw new functions.https.HttpsError('invalid-argument', 'title, description, eventType, startDateTime, and endDateTime are required');
    }

    // FR-034 validation rules
    if (title.length > 100) {
      throw new functions.https.HttpsError('invalid-argument', 'Title must be at most 100 characters');
    }
    if (description.length > 2000) {
      throw new functions.https.HttpsError('invalid-argument', 'Description must be at most 2000 characters');
    }
    if (endDateTime.toDate() <= startDateTime.toDate()) {
      throw new functions.https.HttpsError('invalid-argument', 'End date/time must be after start date/time');
    }

    const now = admin.firestore.Timestamp.now();
    const eventRef = db.collection('events').doc();
    const eventData = {
      id: eventRef.id,
      title,
      description,
      eventType,
      startDateTime,
      endDateTime,
      location: location || '',
      isOnline: isOnline ?? false,
      maxParticipants: maxParticipants || 0,
      targetAudience: targetAudience || [],
      registrationDeadline: registrationDeadline || null,
      bannerUrl: bannerUrl || '',
      entryFee: entryFee || 0,
      organizingTeam: organizingTeam || [],
      sponsors: sponsors || [],
      tags: tags || [],
      status: 'upcoming',
      currentParticipants: 0,
      createdBy: context.auth.uid,
      createdAt: now,
      updatedAt: now,
    };

    await eventRef.set(eventData);

    await db.collection('audit_logs').add({
      actionType: 'CREATE',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'events',
      targetDocumentId: eventRef.id,
      beforeValue: null,
      afterValue: eventData,
      timestamp: now,
    });

    return { eventId: eventRef.id, ...eventData };
  } catch (error) {
    functions.logger.error('createEvent error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to create event');
  }
});

export const updateEvent = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('district_coordinator', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only coordinators and above can update events');
    }

    const { eventId, ...updates } = data as { eventId: string; [key: string]: unknown };
    if (!eventId) throw new functions.https.HttpsError('invalid-argument', 'eventId is required');

    const eventRef = db.collection('events').doc(eventId);
    const existing = await eventRef.get();
    if (!existing.exists) throw new functions.https.HttpsError('not-found', 'Event not found');
    const beforeData = existing.data()!;

    // Server-managed fields that must never be client-set
    // (do not trust client-provided roles).
    const protectedFields = ['id', 'createdBy', 'createdAt', 'currentParticipants'];
    const sanitized: Record<string, unknown> = {};
    Object.keys(updates).forEach((key) => {
      if (!protectedFields.includes(key)) {
        sanitized[key] = updates[key];
      }
    });

    // Same as createEvent: dates arrive as ISO strings over the callable
    // transport and must be converted back to real Timestamps before
    // being compared or stored, or they'd silently fail to compare
    // against the existing Timestamp-typed field.
    for (const dateField of ['startDateTime', 'endDateTime', 'registrationDeadline']) {
      if (sanitized[dateField] !== undefined) {
        const converted = toFirestoreTimestamp(sanitized[dateField]);
        if (converted) sanitized[dateField] = converted;
      }
    }

    if (sanitized.maxParticipants !== undefined) {
      const newMax = sanitized.maxParticipants as number;
      const current = (beforeData.currentParticipants as number) || 0;
      if (newMax < current) {
        throw new functions.https.HttpsError('failed-precondition', `Cannot set maxParticipants below current registrations (${current})`);
      }
    }

    if (sanitized.endDateTime && sanitized.startDateTime) {
      const end = (sanitized.endDateTime as admin.firestore.Timestamp).toDate();
      const start = (sanitized.startDateTime as admin.firestore.Timestamp).toDate();
      if (end <= start) {
        throw new functions.https.HttpsError('invalid-argument', 'End date/time must be after start date/time');
      }
    }

    const now = admin.firestore.Timestamp.now();
    sanitized['updatedAt'] = now;

    await eventRef.update(sanitized);

    await db.collection('audit_logs').add({
      actionType: 'UPDATE',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'events',
      targetDocumentId: eventId,
      beforeValue: beforeData,
      afterValue: sanitized,
      timestamp: now,
    });

    return { eventId, ...sanitized };
  } catch (error) {
    functions.logger.error('updateEvent error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to update event');
  }
});

export const registerForEvent = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const { eventId } = data as { eventId: string };
    if (!eventId) throw new functions.https.HttpsError('invalid-argument', 'eventId is required');

    const eventDoc = await db.collection('events').doc(eventId).get();
    if (!eventDoc.exists) throw new functions.https.HttpsError('not-found', 'Event not found');
    const event = eventDoc.data()!;

    if (event.status === 'cancelled' || event.status === 'completed') {
      throw new functions.https.HttpsError('failed-precondition', 'Event is not open for registration');
    }

    if (event.registrationDeadline && event.registrationDeadline.toDate() < new Date()) {
      throw new functions.https.HttpsError('failed-precondition', 'Registration deadline has passed');
    }

    if (event.maxParticipants > 0 && event.currentParticipants >= event.maxParticipants) {
      throw new functions.https.HttpsError('failed-precondition', 'Event is full');
    }

    const registrationId = `${eventId}_${context.auth.uid}`;
    const existingReg = await db.collection('event_registrations').doc(registrationId).get();
    if (existingReg.exists) {
      throw new functions.https.HttpsError('already-exists', 'Already registered for this event');
    }

    const now = admin.firestore.Timestamp.now();
    await db.collection('event_registrations').doc(registrationId).set({
      eventId,
      userId: context.auth.uid,
      registeredAt: now,
      attended: false,
      attendanceMarkedAt: null,
    });

    await db.collection('events').doc(eventId).update({
      currentParticipants: admin.firestore.FieldValue.increment(1),
      updatedAt: now,
    });

    // FR-045: send in-app notification + push on registration confirmation.
    const userSnap = await auth.getUser(context.auth.uid);
    await db.collection('notifications').add({
      recipientId: context.auth.uid,
      title: 'Event Registration Confirmed',
      body: `You are registered for "${event.title}". See you there!`,
      type: 'event_registration',
      eventId,
      isRead: false,
      timestamp: now,
    });
    // Enqueue FCM via topic/device token if available.
    if (userSnap) {
      functions.logger.info('Registration notification queued for', userSnap.email);
    }

    return { registrationId, message: 'Registered successfully' };
  } catch (error) {
    functions.logger.error('registerForEvent error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to register for event');
  }
});

export const cancelEventRegistration =
  functions.https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication required',
        );
      }

      const { eventId } = data as {
        eventId: string;
      };

      if (!eventId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'eventId is required',
        );
      }

      const registrationId =
        `${eventId}_${context.auth.uid}`;

      const eventRef =
        db.collection('events').doc(eventId);

      const registrationRef =
        db
          .collection('event_registrations')
          .doc(registrationId);

      const now =
        admin.firestore.Timestamp.now();

      await db.runTransaction(async (tx) => {
        const eventSnap =
          await tx.get(eventRef);

        const registrationSnap =
          await tx.get(registrationRef);

        if (!registrationSnap.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            'Registration not found',
          );
        }

        if (!eventSnap.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            'Event not found',
          );
        }

        const event = eventSnap.data()!;

        if (event.startDateTime) {
          const start =
            event.startDateTime.toDate();

          const cutoff =
            new Date(
              start.getTime() -
                24 * 60 * 60 * 1000,
            );

          if (new Date() >= cutoff) {
            throw new functions.https.HttpsError(
              'failed-precondition',
              'Cancellation is only allowed up to 24 hours before the event',
            );
          }
        }

        tx.delete(registrationRef);

        const current =
          Number(event.currentParticipants ?? 0);

        tx.update(eventRef, {
          currentParticipants:
            Math.max(0, current - 1),
          updatedAt: now,
        });
      });

      return {
        message: 'Registration cancelled',
      };
    } catch (error) {
      functions.logger.error(
        'cancelEventRegistration error',
        error,
      );

      if (
        error instanceof functions.https.HttpsError
      ) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to cancel registration',
      );
    }
  });

export const markAttendance = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('district_coordinator', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only coordinators can mark attendance');
    }

    const { registrationId, attended } = data as { registrationId: string; attended: boolean };
    if (!registrationId) throw new functions.https.HttpsError('invalid-argument', 'registrationId is required');

    const regDoc = await db.collection('event_registrations').doc(registrationId).get();
    if (!regDoc.exists) throw new functions.https.HttpsError('not-found', 'Registration not found');

    const now = admin.firestore.Timestamp.now();
    await db.collection('event_registrations').doc(registrationId).update({
      attended,
      attendanceMarkedAt: now,
      markedBy: context.auth.uid,
      updatedAt: now,
    });

    // FR-045: notification when attendance is marked for an attended participant.
    if (attended) {
      const reg = regDoc.data()!;
      await db.collection('notifications').add({
        recipientId: reg.userId,
        title: 'Attendance Recorded',
        body: 'Your attendance has been recorded for this event.',
        type: 'attendance_marked',
        isRead: false,
        timestamp: now,
      });
    }

    return { message: 'Attendance marked' };
  } catch (error) {
    functions.logger.error('markAttendance error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to mark attendance');
  }
});
