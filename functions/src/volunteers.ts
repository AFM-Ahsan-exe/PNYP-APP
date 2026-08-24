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

export const applyAsVolunteer = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');

    const { opportunityId, motivation, availability, skills } = data as {
      opportunityId: string;
      motivation: string;
      availability: string;
      skills: string[];
    };

    if (!opportunityId || !motivation || !availability) {
      throw new functions.https.HttpsError('invalid-argument', 'opportunityId, motivation, and availability are required');
    }

    const opportunityDoc = await db.collection('opportunities').doc(opportunityId).get();
    if (!opportunityDoc.exists) throw new functions.https.HttpsError('not-found', 'Opportunity not found');

    const now = admin.firestore.Timestamp.now();
    const applicationRef = db.collection('volunteers').doc();
    const applicationData = {
      id: applicationRef.id,
      userId: context.auth.uid,
      opportunityId,
      motivation,
      availability,
      skills: skills || [],
      status: 'pending',
      appliedAt: now,
      reviewedAt: null,
      reviewedBy: null,
      createdAt: now,
      updatedAt: now,
    };

    await applicationRef.set(applicationData);

    await db.collection('audit_logs').add({
      actionType: 'CREATE',
      userId: context.auth.uid,
      userRole: 'member',
      targetCollection: 'volunteers',
      targetDocumentId: applicationRef.id,
      beforeValue: null,
      afterValue: applicationData,
      timestamp: now,
    });

    return { applicationId: applicationRef.id, ...applicationData };
  } catch (error) {
    functions.logger.error('applyAsVolunteer error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to submit volunteer application');
  }
});

export const updateVolunteerStatus = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('opportunity_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only opportunity managers and above can update volunteer status');
    }

    const { applicationId, status, reviewNotes } = data as {
      applicationId: string;
      status: 'accepted' | 'rejected' | 'completed';
      reviewNotes?: string;
    };

    if (!applicationId || !status) {
      throw new functions.https.HttpsError('invalid-argument', 'applicationId and status are required');
    }

    const applicationDoc = await db.collection('volunteers').doc(applicationId).get();
    if (!applicationDoc.exists) throw new functions.https.HttpsError('not-found', 'Application not found');

    const now = admin.firestore.Timestamp.now();
    const updateData: Record<string, unknown> = {
      status,
      reviewedAt: now,
      reviewedBy: context.auth.uid,
      updatedAt: now,
    };

    if (reviewNotes !== undefined) updateData.reviewNotes = reviewNotes;

    await db.collection('volunteers').doc(applicationId).update(updateData);

    await db.collection('audit_logs').add({
      actionType: status === 'accepted' ? 'APPROVE' : 'REJECT',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'volunteers',
      targetDocumentId: applicationId,
      beforeValue: { status: 'pending' },
      afterValue: { status, reviewNotes },
      timestamp: now,
    });

    return { message: `Volunteer application ${status}` };
  } catch (error) {
    functions.logger.error('updateVolunteerStatus error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to update volunteer status');
  }
});

export const getVolunteerDirectory = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('opportunity_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only opportunity managers and above can view volunteer directory');
    }

    const { status, opportunityId } = data as { status?: string; opportunityId?: string };

    let query: admin.firestore.Query = db.collection('volunteers');

    if (status) {
      query = query.where('status', '==', status);
    }

    if (opportunityId) {
      query = query.where('opportunityId', '==', opportunityId);
    }

    const snapshot = await query.orderBy('appliedAt', 'desc').limit(100).get();

    const volunteers = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return { volunteers };
  } catch (error) {
    functions.logger.error('getVolunteerDirectory error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to load volunteer directory');
  }
});
