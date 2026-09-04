import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

const VALID_MEMBERSHIP_TYPES = [
  'youth_mpa',
  'youth_mna',
  'youth_senator',
  'youth_judge',
];

/**
 * Lets a signed-in member submit a membership renewal request.
 * Runs with admin privileges so it can set `status` back to
 * 'pending' and record the requested type + payment proof -
 * fields the client is deliberately blocked from writing
 * directly by firestore.rules. membershipStartDate/expiryDate
 * are NOT set here - those are only set by approveMember once a
 * coordinator actually approves the renewal.
 */
export const submitRenewal = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }

    const uid = context.auth.uid;
    const { membershipType, paymentProofUrl } = data as {
      membershipType: string;
      paymentProofUrl: string;
    };

    if (!membershipType || !VALID_MEMBERSHIP_TYPES.includes(membershipType)) {
      throw new functions.https.HttpsError('invalid-argument', 'A valid membershipType is required');
    }
    if (!paymentProofUrl || typeof paymentProofUrl !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'paymentProofUrl is required');
    }

    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User profile not found');
    }

    const now = admin.firestore.Timestamp.now();

    await userRef.update({
      membershipType,
      status: 'pending',
      paymentProofUrl,
      updatedAt: now,
    });

    await db.collection('payments').add({
      userId: uid,
      paymentType: 'membership_renewal',
      year: new Date().getFullYear(),
      status: 'pending',
      proofUrl: paymentProofUrl,
      createdAt: now,
      updatedAt: now,
    });

    return { message: 'Renewal request submitted' };
  } catch (error) {
    functions.logger.error('submitRenewal error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to submit renewal');
  }
});