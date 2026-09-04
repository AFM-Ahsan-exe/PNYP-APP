import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { isAtLeastRole } from './helpers';

const db = admin.firestore();
const auth = admin.auth();
const storage = admin.storage();

function extractStoragePath(value: string): string | null {
  try {
    if (value.startsWith('gs://')) {
      const withoutScheme = value.substring(5);
      const slash = withoutScheme.indexOf('/');
      if (slash === -1) return null;
      return withoutScheme.substring(slash + 1);
    }

    const url = new URL(value);
    const encoded = url.pathname.match(/\/o\/(.+)$/);
    if (!encoded) return null;
    return decodeURIComponent(encoded[1]);
  } catch {
    return null;
  }
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

export const updateDocument = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only content managers and above can update documents');
    }

    const { documentId, title, description, category, accessLevel, tags } = data as {
      documentId: string;
      title?: string;
      description?: string;
      category?: string;
      accessLevel?: 'public' | 'members_only' | 'admin_only';
      tags?: string[];
    };

    if (!documentId) throw new functions.https.HttpsError('invalid-argument', 'documentId is required');

    const docRef = db.collection('documents').doc(documentId);
    const docSnap = await docRef.get();
    if (!docSnap.exists) throw new functions.https.HttpsError('not-found', 'Document not found');

    const updates: Record<string, unknown> = { updatedAt: admin.firestore.Timestamp.now() };
    if (title !== undefined) updates.title = title;
    if (description !== undefined) updates.description = description;
    if (category !== undefined) updates.category = category;
    if (accessLevel !== undefined) updates.accessLevel = accessLevel;
    if (tags !== undefined) updates.tags = tags;

    await docRef.update(updates);

    const afterValue = { ...docSnap.data(), ...updates };
    await db.collection('audit_logs').add({
      actionType: 'UPDATE',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'documents',
      targetDocumentId: documentId,
      beforeValue: docSnap.data(),
      afterValue,
      timestamp: admin.firestore.Timestamp.now(),
    });

    return { message: 'Document updated' };
  } catch (error) {
    functions.logger.error('updateDocument error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to update document');
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

    const docRef = db.collection('documents').doc(documentId);
    const docSnap = await docRef.get();
    if (!docSnap.exists) throw new functions.https.HttpsError('not-found', 'Document not found');

    const fileUrl = docSnap.data()?.fileUrl as string | undefined;

    await docRef.delete();

    if (fileUrl) {
      const storagePath = extractStoragePath(fileUrl);
      if (storagePath) {
        try {
          const bucket = storage.bucket();
          const file = bucket.file(storagePath);
          await file.delete();
        } catch (storageError) {
          functions.logger.warn('Failed to delete Storage file', storageError);
        }
      }
    }

    await db.collection('audit_logs').add({
      actionType: 'DELETE',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'documents',
      targetDocumentId: documentId,
      beforeValue: docSnap.data(),
      afterValue: null,
      timestamp: admin.firestore.Timestamp.now(),
    });

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