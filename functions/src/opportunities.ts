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

export const createOpportunity = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('opportunity_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only opportunity managers and above can create opportunities');
    }

    const { title, description, organization, location, isRemote, deadline, applyUrl, tags, targetAudience } = data as {
      title: string;
      description: string;
      organization: string;
      location?: string;
      isRemote?: boolean;
      deadline?: admin.firestore.Timestamp;
      applyUrl: string;
      tags?: string[];
      targetAudience?: string[];
    };

    if (!title || !description || !organization || !applyUrl) {
      throw new functions.https.HttpsError('invalid-argument', 'title, description, organization, and applyUrl are required');
    }

    const now = admin.firestore.Timestamp.now();
    const opportunityRef = db.collection('opportunities').doc();
    const opportunityData = {
      id: opportunityRef.id,
      title,
      description,
      organization,
      location: location || '',
      isRemote: isRemote ?? false,
      deadline: deadline || null,
      applyUrl,
      tags: tags || [],
      targetAudience: targetAudience || [],
      status: 'active',
      viewCount: 0,
      clickCount: 0,
      createdBy: context.auth.uid,
      createdAt: now,
      updatedAt: now,
    };

    await opportunityRef.set(opportunityData);

    await db.collection('audit_logs').add({
      actionType: 'CREATE',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'opportunities',
      targetDocumentId: opportunityRef.id,
      beforeValue: null,
      afterValue: opportunityData,
      timestamp: now,
    });

    return { opportunityId: opportunityRef.id, ...opportunityData };
  } catch (error) {
    functions.logger.error('createOpportunity error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to create opportunity');
  }
});

export const trackOpportunityClick = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');

    const { opportunityId } = data as { opportunityId: string };
    if (!opportunityId) throw new functions.https.HttpsError('invalid-argument', 'opportunityId is required');

    await db.collection('opportunities').doc(opportunityId).update({
      clickCount: admin.firestore.FieldValue.increment(1),
    });

    return { message: 'Click tracked' };
  } catch (error) {
    functions.logger.error('trackOpportunityClick error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to track click');
  }
});

export const updateOpportunity = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('opportunity_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only opportunity managers and above can update opportunities');
    }

    const { opportunityId, title, description, organization, location, isRemote, deadline, applyUrl, tags, targetAudience, status } = data as {
      opportunityId: string;
      title?: string;
      description?: string;
      organization?: string;
      location?: string;
      isRemote?: boolean;
      deadline?: admin.firestore.Timestamp;
      applyUrl?: string;
      tags?: string[];
      targetAudience?: string[];
      status?: string;
    };

    if (!opportunityId) throw new functions.https.HttpsError('invalid-argument', 'opportunityId is required');

    const opportunityDoc = await db.collection('opportunities').doc(opportunityId).get();
    if (!opportunityDoc.exists) throw new functions.https.HttpsError('not-found', 'Opportunity not found');

    const updateData: Record<string, unknown> = { updatedAt: admin.firestore.Timestamp.now() };
    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (organization !== undefined) updateData.organization = organization;
    if (location !== undefined) updateData.location = location;
    if (isRemote !== undefined) updateData.isRemote = isRemote;
    if (deadline !== undefined) updateData.deadline = deadline;
    if (applyUrl !== undefined) updateData.applyUrl = applyUrl;
    if (tags !== undefined) updateData.tags = tags;
    if (targetAudience !== undefined) updateData.targetAudience = targetAudience;
    if (status !== undefined) updateData.status = status;

    await db.collection('opportunities').doc(opportunityId).update(updateData);

    return { message: 'Opportunity updated' };
  } catch (error) {
    functions.logger.error('updateOpportunity error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to update opportunity');
  }
});

export const deleteOpportunity = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('opportunity_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only opportunity managers and above can delete opportunities');
    }

    const { opportunityId } = data as { opportunityId: string };
    if (!opportunityId) throw new functions.https.HttpsError('invalid-argument', 'opportunityId is required');

    await db.collection('opportunities').doc(opportunityId).delete();

    return { message: 'Opportunity deleted' };
  } catch (error) {
    functions.logger.error('deleteOpportunity error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to delete opportunity');
  }
});
