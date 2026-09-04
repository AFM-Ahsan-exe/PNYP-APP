import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { isAtLeastRole } from './helpers';

const db = admin.firestore();
const auth = admin.auth();

/**
 * TASK 25:
 * Server-side sanitization for news rich text.
 * Removes dangerous script/iframe content, javascript: URLs,
 * and inline event-handler attributes.
 */
function sanitizeText(value: unknown, maxLength: number): string {
  if (typeof value !== 'string') {
    return '';
  }

  return value
    .replace(/<script[\s\S]*?>[\s\S]*?<\/script>/gi, '')
    .replace(/<iframe[\s\S]*?>[\s\S]*?<\/iframe>/gi, '')
    .replace(/javascript:/gi, '')
    .replace(/on[a-z]+\s*=/gi, '')
    .trim()
    .slice(0, maxLength);
}

export const createNewsArticle = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required'
      );
    }

    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};

    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only content managers and above can create articles'
      );
    }

    const {
      title,
      content,
      summary,
      coverImageUrl,
      tags,
      targetAudience,
      isPublished,
    } = data as {
      title: string;
      content: string;
      summary?: string;
      coverImageUrl?: string;
      tags?: string[];
      targetAudience?: string[];
      isPublished?: boolean;
    };

    if (!title || !content) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'title and content are required'
      );
    }

    // TASK 25: Sanitize all news text before saving.
    const safeTitle = sanitizeText(title, 200);
    const safeSummary = sanitizeText(summary, 500);
    const safeContent = sanitizeText(content, 20000);

    if (!safeTitle || !safeContent) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'title and content are required after sanitization'
      );
    }

    const now = admin.firestore.Timestamp.now();
    const articleRef = db.collection('news').doc();

    const articleData = {
      id: articleRef.id,
      title: safeTitle,
      content: safeContent,
      summary: safeSummary,
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
        title: 'New Article: ' + safeTitle,
        body: safeSummary || safeContent.substring(0, 150),
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

    return {
      articleId: articleRef.id,
      ...articleData,
    };
  } catch (error) {
    functions.logger.error('createNewsArticle error', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to create article'
    );
  }
});

export const updateNewsArticle = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required'
      );
    }

    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};

    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only content managers and above can update articles'
      );
    }

    const {
      articleId,
      title,
      content,
      summary,
      coverImageUrl,
      tags,
      targetAudience,
      isPublished,
    } = data as {
      articleId: string;
      title?: string;
      content?: string;
      summary?: string;
      coverImageUrl?: string;
      tags?: string[];
      targetAudience?: string[];
      isPublished?: boolean;
    };

    if (!articleId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'articleId is required'
      );
    }

    const articleDoc = await db.collection('news').doc(articleId).get();

    if (!articleDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Article not found'
      );
    }

    const updates: Record<string, unknown> = {
      updatedAt: admin.firestore.Timestamp.now(),
    };

    // TASK 25: Sanitize only fields that are being updated.
    if (title !== undefined) {
      updates.title = sanitizeText(title, 200);
    }

    if (content !== undefined) {
      updates.content = sanitizeText(content, 20000);
    }

    if (summary !== undefined) {
      updates.summary = sanitizeText(summary, 500);
    }

    if (coverImageUrl !== undefined) {
      updates.coverImageUrl = coverImageUrl;
    }

    if (tags !== undefined) {
      updates.tags = tags;
    }

    if (targetAudience !== undefined) {
      updates.targetAudience = targetAudience;
    }

    if (isPublished !== undefined) {
      updates.isPublished = isPublished;
      updates.publishedAt = isPublished
        ? admin.firestore.Timestamp.now()
        : null;
    }

    // Prevent empty title/content from being saved after sanitization.
    if (title !== undefined && updates.title === '') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'title cannot be empty after sanitization'
      );
    }

    if (content !== undefined && updates.content === '') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'content cannot be empty after sanitization'
      );
    }

    await db.collection('news').doc(articleId).update(updates);

    return { message: 'Article updated' };
  } catch (error) {
    functions.logger.error('updateNewsArticle error', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to update article'
    );
  }
});

export const deleteNewsArticle = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required'
      );
    }

    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};

    if (!isAtLeastRole('content_manager', claims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only content managers and above can delete articles'
      );
    }

    const { articleId } = data as { articleId: string };

    if (!articleId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'articleId is required'
      );
    }

    await db.collection('news').doc(articleId).delete();

    return { message: 'Article deleted' };
  } catch (error) {
    functions.logger.error('deleteNewsArticle error', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to delete article'
    );
  }
});

async function sendBroadcastNotification(params: {
  title: string;
  body: string;
  type: string;
  targetAudience: string[];
}) {
  let recipientUids: string[] = [];

  if (params.targetAudience.length === 0) {
    const usersSnapshot = await db.collection('users').get();
    recipientUids = usersSnapshot.docs.map((doc) => doc.id);
  } else {
    const usersSnapshot = await db
      .collection('users')
      .where('province', 'in', params.targetAudience)
      .get();

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

