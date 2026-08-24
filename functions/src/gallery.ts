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
    const media = mediaDoc.data()!;

    await db.collection('gallery_media').doc(mediaId).delete();
    await db.collection('gallery_albums').doc(media.albumId).update({
      mediaCount: admin.firestore.FieldValue.increment(-1),
      updatedAt: admin.firestore.Timestamp.now(),
    });

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

    await db.collection('gallery_albums').doc(albumId).delete();

    return { message: 'Album deleted' };
  } catch (error) {
    functions.logger.error('deleteAlbum error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to delete album');
  }
});
