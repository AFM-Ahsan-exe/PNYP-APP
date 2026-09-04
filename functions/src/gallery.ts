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

function validateStorageUrl(url: string | undefined): boolean {
  if (!url) return true;
  return url.includes('firebasestorage.googleapis.com') || url.includes('storage.googleapis.com');
}

export const createAlbum = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only content managers and above can create albums');
    }

    const { title, description, coverImageUrl, tags, isPublic } = data as {
      title: string;
      description: string;
      coverImageUrl?: string;
      tags?: string[];
      isPublic?: boolean;
    };

    if (!title) {
      throw new functions.https.HttpsError('invalid-argument', 'title is required');
    }

    const now = admin.firestore.Timestamp.now();
    const albumRef = db.collection('gallery_albums').doc();
    const albumData = {
      id: albumRef.id,
      title,
      description: description || '',
      coverImageUrl: coverImageUrl || '',
      tags: tags || [],
      isPublic: isPublic ?? true,
      mediaCount: 0,
      createdBy: context.auth.uid,
      createdAt: now,
      updatedAt: now,
    };

    await albumRef.set(albumData);

    await db.collection('audit_logs').add({
      actionType: 'CREATE',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'gallery_albums',
      targetDocumentId: albumRef.id,
      beforeValue: null,
      afterValue: albumData,
      timestamp: now,
    });

    return { albumId: albumRef.id, ...albumData };
  } catch (error) {
    functions.logger.error('createAlbum error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to create album');
  }
});

export const updateAlbum = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only content managers and above can update albums');
    }

    const { albumId, title, description, coverImageUrl, tags, isPublic } = data as {
      albumId: string;
      title?: string;
      description?: string;
      coverImageUrl?: string;
      tags?: string[];
      isPublic?: boolean;
    };

    if (!albumId) throw new functions.https.HttpsError('invalid-argument', 'albumId is required');

    const albumRef = db.collection('gallery_albums').doc(albumId);
    const albumSnap = await albumRef.get();
    if (!albumSnap.exists) throw new functions.https.HttpsError('not-found', 'Album not found');

    const updates: Record<string, unknown> = { updatedAt: admin.firestore.Timestamp.now() };
    if (title !== undefined) updates.title = title;
    if (description !== undefined) updates.description = description;
    if (coverImageUrl !== undefined) {
      if (!validateStorageUrl(coverImageUrl)) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid coverImageUrl');
      }
      updates.coverImageUrl = coverImageUrl;
    }
    if (tags !== undefined) updates.tags = tags;
    if (isPublic !== undefined) updates.isPublic = isPublic;

    await albumRef.update(updates);

    const afterValue = { ...albumSnap.data(), ...updates };
    await db.collection('audit_logs').add({
      actionType: 'UPDATE',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'gallery_albums',
      targetDocumentId: albumId,
      beforeValue: albumSnap.data(),
      afterValue,
      timestamp: admin.firestore.Timestamp.now(),
    });

    return { message: 'Album updated' };
  } catch (error) {
    functions.logger.error('updateAlbum error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to update album');
  }
});

export const addMediaToAlbum = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only content managers and above can add media');
    }

    const { albumId, mediaUrl, mediaType, thumbnailUrl, caption, tags } = data as {
      albumId: string;
      mediaUrl: string;
      mediaType: 'image' | 'video';
      thumbnailUrl?: string;
      caption?: string;
      tags?: string[];
    };

    if (!albumId || !mediaUrl || !mediaType) {
      throw new functions.https.HttpsError('invalid-argument', 'albumId, mediaUrl, and mediaType are required');
    }

    if (!validateStorageUrl(mediaUrl)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid mediaUrl');
    }

    const albumDoc = await db.collection('gallery_albums').doc(albumId).get();
    if (!albumDoc.exists) throw new functions.https.HttpsError('not-found', 'Album not found');

    const now = admin.firestore.Timestamp.now();
    const mediaRef = db.collection('gallery_media').doc();
    const mediaData = {
      id: mediaRef.id,
      albumId,
      mediaUrl,
      mediaType,
      thumbnailUrl: thumbnailUrl || '',
      caption: caption || '',
      tags: tags || [],
      uploadedBy: context.auth.uid,
      createdAt: now,
      updatedAt: now,
    };

    await mediaRef.set(mediaData);

    await db.collection('gallery_albums').doc(albumId).update({
      mediaCount: admin.firestore.FieldValue.increment(1),
      updatedAt: now,
    });

    return { mediaId: mediaRef.id, ...mediaData };
  } catch (error) {
    functions.logger.error('addMediaToAlbum error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to add media');
  }
});

export const deleteMedia = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only content managers and above can delete media');
    }

    const { mediaId } = data as { mediaId: string };
    if (!mediaId) throw new functions.https.HttpsError('invalid-argument', 'mediaId is required');

    const mediaDoc = await db.collection('gallery_media').doc(mediaId).get();
    if (!mediaDoc.exists) throw new functions.https.HttpsError('not-found', 'Media not found');
    const mediaData = mediaDoc.data()!;
    const mediaUrl = mediaData.mediaUrl as string | undefined;

    await db.collection('gallery_media').doc(mediaId).delete();
    await db.collection('gallery_albums').doc(mediaData.albumId).update({
      mediaCount: admin.firestore.FieldValue.increment(-1),
      updatedAt: admin.firestore.Timestamp.now(),
    });

    if (mediaUrl) {
      const storagePath = extractStoragePath(mediaUrl);
      if (storagePath) {
        try {
          const bucket = storage.bucket();
          const file = bucket.file(storagePath);
          await file.delete();
        } catch (storageError) {
          functions.logger.warn('Gallery Storage cleanup failed', storageError);
        }
      }
    }

    return { message: 'Media deleted' };
  } catch (error) {
    functions.logger.error('deleteMedia error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to delete media');
  }
});

export const deleteAlbum = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only content managers and above can delete albums');
    }

    const { albumId } = data as { albumId: string };
    if (!albumId) throw new functions.https.HttpsError('invalid-argument', 'albumId is required');

    const albumDoc = await db.collection('gallery_albums').doc(albumId).get();
    if (!albumDoc.exists) throw new functions.https.HttpsError('not-found', 'Album not found');

    const mediaSnapshot = await db.collection('gallery_media').where('albumId', '==', albumId).get();
    const batch = db.batch();
    for (const mediaDoc of mediaSnapshot.docs) {
      batch.delete(mediaDoc.ref);
    }
    batch.delete(db.collection('gallery_albums').doc(albumId));
    await batch.commit();

    return { message: 'Album and its media deleted' };
  } catch (error) {
    functions.logger.error('deleteAlbum error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to delete album');
  }
});