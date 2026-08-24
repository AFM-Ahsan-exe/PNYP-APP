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

export const uploadDocument = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only content managers and above can upload documents');
    }

    const { title, description, fileUrl, fileType, fileSize, category, accessLevel, tags } = data as {
      title: string;
      description: string;
      fileUrl: string;
      fileType: string;
      fileSize: number;
      category?: string;
      accessLevel: 'public' | 'members_only' | 'admin_only';
      tags?: string[];
    };

    if (!title || !fileUrl || !fileType || !accessLevel) {
      throw new functions.https.HttpsError('invalid-argument', 'title, fileUrl, fileType, and accessLevel are required');
    }

    const now = admin.firestore.Timestamp.now();
    const docRef = db.collection('documents').doc();
    const documentData = {
      id: docRef.id,
      title,
      description: description || '',
      fileUrl,
      fileType,
      fileSize: fileSize || 0,
      category: category || 'general',
      accessLevel,
      tags: tags || [],
      uploadedBy: context.auth.uid,
      uploaderName: callerToken.displayName || 'Unknown',
      downloadCount: 0,
      createdAt: now,
      updatedAt: now,
    };

    await docRef.set(documentData);

    await db.collection('audit_logs').add({
      actionType: 'CREATE',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'documents',
      targetDocumentId: docRef.id,
      beforeValue: null,
      afterValue: documentData,
      timestamp: now,
    });

    return { documentId: docRef.id, ...documentData };
  } catch (error) {
    functions.logger.error('uploadDocument error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to upload document');
  }
});

export const deleteDocument = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only content managers and above can delete documents');
    }

    const { documentId } = data as { documentId: string };
    if (!documentId) throw new functions.https.HttpsError('invalid-argument', 'documentId is required');

    await db.collection('documents').doc(documentId).delete();

    return { message: 'Document deleted' };
  } catch (error) {
    functions.logger.error('deleteDocument error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to delete document');
  }
});

export const incrementDocumentDownload = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');

    const { documentId } = data as { documentId: string };
    if (!documentId) throw new functions.https.HttpsError('invalid-argument', 'documentId is required');

    await db.collection('documents').doc(documentId).update({
      downloadCount: admin.firestore.FieldValue.increment(1),
    });

    return { message: 'Download count updated' };
  } catch (error) {
    functions.logger.error('incrementDocumentDownload error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to update download count');
  }
});
