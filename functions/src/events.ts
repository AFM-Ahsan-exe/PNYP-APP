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

export const createEvent = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('district_coordinator', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only coordinators and above can create events');
    }

    const { title, description, eventType, startDateTime, endDateTime, location, isOnline, maxParticipants, targetAudience, registrationDeadline, bannerUrl, entryFee, organizingTeam, sponsors, tags } = data as {
      title: string;
      description: string;
      eventType: string;
      startDateTime: admin.firestore.Timestamp;
      endDateTime: admin.firestore.Timestamp;
      location?: string;
      isOnline?: boolean;
      maxParticipants?: number;
      targetAudience?: string[];
      registrationDeadline?: admin.firestore.Timestamp;
      bannerUrl?: string;
      entryFee?: number;
      organizingTeam?: string[];
      sponsors?: string[];
      tags?: string[];
    };

    if (!title || !description || !eventType || !startDateTime || !endDateTime) {
      throw new functions.https.HttpsError('invalid-argument', 'title, description, eventType, startDateTime, and endDateTime are required');
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

    return { registrationId, message: 'Registered successfully' };
  } catch (error) {
    functions.logger.error('registerForEvent error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to register for event');
  }
});

export const cancelEventRegistration = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const { eventId } = data as { eventId: string };
    if (!eventId) throw new functions.https.HttpsError('invalid-argument', 'eventId is required');

    const registrationId = `${eventId}_${context.auth.uid}`;
    const regDoc = await db.collection('event_registrations').doc(registrationId).get();
    if (!regDoc.exists) throw new functions.https.HttpsError('not-found', 'Registration not found');

    const now = admin.firestore.Timestamp.now();
    await db.collection('event_registrations').doc(registrationId).delete();

    await db.collection('events').doc(eventId).update({
      currentParticipants: admin.firestore.FieldValue.increment(-1),
      updatedAt: now,
    });

    return { message: 'Registration cancelled' };
  } catch (error) {
    functions.logger.error('cancelEventRegistration error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to cancel registration');
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

    return { message: 'Attendance marked' };
  } catch (error) {
    functions.logger.error('markAttendance error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to mark attendance');
  }
});
