import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const searchContent = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');

    const query = String(data['query'] || '').trim();
    const limit = Number(data['limit'] ?? 20);
    const cursor = data['cursor'] as string | undefined;

    if (!query) {
      throw new functions.https.HttpsError('invalid-argument', 'Query is required');
    }

    const lower = query.toLowerCase();
    const results: Array<Record<string, unknown>> = [];

    // These previously ran `.get()` with no limit, downloading every
    // document in each collection on every single search - increasingly
    // expensive and slow as the collections grow, and a clear
    // "unnecessary requests" cost/performance issue. A `.limit()` here
    // is a safety cap, not a real search index - it keeps read costs
    // bounded, though it means very old matching documents may not
    // surface once a collection exceeds this cap. A proper fix (Algolia/
    // Typesense/full-text search) is a bigger architectural change than
    // a bug-fix pass should make unprompted.
    const SCAN_LIMIT = 500;

    const eventSnapshot = await db.collection('events').limit(SCAN_LIMIT).get();
    for (const doc of eventSnapshot.docs) {
      const event = doc.data() as Record<string, unknown>;
      const title = String(event['title'] ?? '').toLowerCase();
      const eventType = String(event['eventType'] ?? '').toLowerCase();
      const location = String(event['location'] ?? '').toLowerCase();
      if (title.includes(lower) || eventType.includes(lower) || location.includes(lower)) {
        results.push({
          'type': 'event',
          'id': doc.id,
          'title': event['title'],
          'subtitle': event['eventType'] ?? 'Event',
          'data': event,
        });
      }
    }

    const newsSnapshot = await db.collection('news').limit(SCAN_LIMIT).get();
    for (const doc of newsSnapshot.docs) {
      const article = doc.data() as Record<string, unknown>;
      const title = String(article['title'] ?? '').toLowerCase();
      const category = String(article['category'] ?? '').toLowerCase();
      const content = String(article['content'] ?? '').toLowerCase();
      if (title.includes(lower) || category.includes(lower) || content.includes(lower)) {
        results.push({
          'type': 'news',
          'id': doc.id,
          'title': article['title'],
          'subtitle': article['category'] ?? 'News',
          'data': article,
        });
      }
    }

    const opportunitySnapshot = await db.collection('opportunities').limit(SCAN_LIMIT).get();
    for (const doc of opportunitySnapshot.docs) {
      const opportunity = doc.data() as Record<string, unknown>;
      const title = String(opportunity['title'] ?? '').toLowerCase();
      const description = String(opportunity['description'] ?? '').toLowerCase();
      const location = String(opportunity['location'] ?? '').toLowerCase();
      if (title.includes(lower) || description.includes(lower) || location.includes(lower)) {
        results.push({
          'type': 'opportunity',
          'id': doc.id,
          'title': opportunity['title'],
          'subtitle': opportunity['location'] ?? 'Opportunity',
          'data': opportunity,
        });
      }
    }

    const startIdx = cursor ? Number(cursor) : 0;
    const endIdx = Math.min(startIdx + limit, results.length);
    const page = results.slice(startIdx, endIdx);
    const nextCursor = endIdx < results.length ? String(endIdx) : undefined;

    return {
      results: page,
      nextCursor,
      total: results.length,
    };
  } catch (error) {
    functions.logger.error('searchContent error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Search failed');
  }
});
