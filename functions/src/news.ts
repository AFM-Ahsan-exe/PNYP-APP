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

export const createNewsArticle = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only content managers and above can create articles');
    }

    const { title, content, summary, coverImageUrl, tags, targetAudience, isPublished } = data as {
      title: string;
      content: string;
      summary?: string;
      coverImageUrl?: string;
      tags?: string[];
      targetAudience?: string[];
      isPublished?: boolean;
    };

    if (!title || !content) {
      throw new functions.https.HttpsError('invalid-argument', 'title and content are required');
    }

    const now = admin.firestore.Timestamp.now();
    const articleRef = db.collection('news').doc();
    const articleData = {
      id: articleRef.id,
      title,
      content,
      summary: summary || '',
      coverImageUrl: coverImageUrl || '',
      tags: tags || [],
      targetAudience: targetAudience || [],
      isPublished: isPublished ?? false,
      publishedAt: isPublished ? now : null,
      authorId: context.auth.uid,
      authorName: callerToken.displayName || 'Unknown',
      createdAt: now,
      updatedAt: now,
    };

    await articleRef.set(articleData);

    if (isPublished) {
      await sendBroadcastNotification({
        title: 'New Article: ' + title,
        body: summary || content.substring(0, 150),
        type: 'news',
        targetAudience: targetAudience || [],
      });
    }

    await db.collection('audit_logs').add({
      actionType: 'CREATE',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'news',
      targetDocumentId: articleRef.id,
      beforeValue: null,
      afterValue: articleData,
      timestamp: now,
    });

    return { articleId: articleRef.id, ...articleData };
  } catch (error) {
    functions.logger.error('createNewsArticle error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to create article');
  }
});

export const updateNewsArticle = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only content managers and above can update articles');
    }

    const { articleId, title, content, summary, coverImageUrl, tags, targetAudience, isPublished } = data as {
      articleId: string;
      title?: string;
      content?: string;
      summary?: string;
      coverImageUrl?: string;
      tags?: string[];
      targetAudience?: string[];
      isPublished?: boolean;
    };

    if (!articleId) throw new functions.https.HttpsError('invalid-argument', 'articleId is required');

    const articleDoc = await db.collection('news').doc(articleId).get();
    if (!articleDoc.exists) throw new functions.https.HttpsError('not-found', 'Article not found');

    const updates: Record<string, unknown> = { updatedAt: admin.firestore.Timestamp.now() };
    if (title !== undefined) updates.title = title;
    if (content !== undefined) updates.content = content;
    if (summary !== undefined) updates.summary = summary;
    if (coverImageUrl !== undefined) updates.coverImageUrl = coverImageUrl;
    if (tags !== undefined) updates.tags = tags;
    if (targetAudience !== undefined) updates.targetAudience = targetAudience;
    if (isPublished !== undefined) {
      updates.isPublished = isPublished;
      updates.publishedAt = isPublished ? admin.firestore.Timestamp.now() : null;
    }

    await db.collection('news').doc(articleId).update(updates);

    return { message: 'Article updated' };
  } catch (error) {
    functions.logger.error('updateNewsArticle error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to update article');
  }
});

export const deleteNewsArticle = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only content managers and above can delete articles');
    }

    const { articleId } = data as { articleId: string };
    if (!articleId) throw new functions.https.HttpsError('invalid-argument', 'articleId is required');

    await db.collection('news').doc(articleId).delete();

    return { message: 'Article deleted' };
  } catch (error) {
    functions.logger.error('deleteNewsArticle error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to delete article');
  }
});

async function sendBroadcastNotification(params: { title: string; body: string; type: string; targetAudience: string[] }) {
  let recipientUids: string[] = [];
  if (params.targetAudience.length === 0) {
    const usersSnapshot = await db.collection('users').get();
    recipientUids = usersSnapshot.docs.map((doc) => doc.id);
  } else {
    const usersSnapshot = await db.collection('users').where('province', 'in', params.targetAudience).get();
    recipientUids = usersSnapshot.docs.map((doc) => doc.id);
  }

  const notificationPromises = recipientUids.map((uid) =>
    db.collection('notifications').add({
      recipientId: uid,
      title: params.title,
      body: params.body,
      type: params.type,
      isRead: false,
      timestamp: admin.firestore.Timestamp.now(),
    })
  );

  await Promise.all(notificationPromises);
}
