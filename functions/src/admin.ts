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

export const updateUserRole = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('president', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only presidents and super admins can update roles');
    }

    const { uid, role, admin: adminClaim } = data as { uid: string; role: string; admin?: boolean };
    if (!uid || !role) {
      throw new functions.https.HttpsError('invalid-argument', 'uid and role are required');
    }

    const validRoles = ['member', 'district_coordinator', 'regional_coordinator', 'content_manager', 'opportunity_manager', 'national_admin', 'president', 'super_admin'];
    if (!validRoles.includes(role)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid role');
    }

    const targetUser = await auth.getUser(uid);
    const previousClaims = targetUser.customClaims || {};

    await auth.setCustomUserClaims(uid, {
      role,
      admin: adminClaim ?? previousClaims.admin ?? false,
    });

    await db.collection('audit_logs').add({
      actionType: 'UPDATE',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'users',
      targetDocumentId: uid,
      beforeValue: { role: previousClaims.role, admin: previousClaims.admin },
      afterValue: { role, admin: adminClaim ?? previousClaims.admin ?? false },
      timestamp: admin.firestore.Timestamp.now(),
    });

    return { message: 'Role updated successfully' };
  } catch (error) {
    functions.logger.error('updateUserRole error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to update role');
  }
});

export const getAuditLogs = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (!isAtLeastRole('national_admin', claims)) {
      throw new functions.https.HttpsError('permission-denied', 'Only national admins and above can view audit logs');
    }

    const { startDate, endDate, actionType, userId } = data as {
      startDate?: admin.firestore.Timestamp;
      endDate?: admin.firestore.Timestamp;
      actionType?: string;
      userId?: string;
    };

    let query: admin.firestore.Query = db.collection('audit_logs');

    if (startDate) query = query.where('timestamp', '>=', startDate);
    if (endDate) query = query.where('timestamp', '<=', endDate);
    if (actionType) query = query.where('actionType', '==', actionType);
    if (userId) query = query.where('userId', '==', userId);

    const snapshot = await query.orderBy('timestamp', 'desc').limit(200).get();
    const logs = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    return { logs };
  } catch (error) {
    functions.logger.error('getAuditLogs error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to load audit logs');
  }
});

export const updateSystemSettings = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};
    if (claims.role !== 'super_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only super admins can update system settings');
    }

    const { settings } = data as { settings: Record<string, unknown> };
    if (!settings || typeof settings !== 'object') {
      throw new functions.https.HttpsError('invalid-argument', 'settings object is required');
    }

    const now = admin.firestore.Timestamp.now();
    const updatePromises = Object.entries(settings).map(([key, value]) =>
      db.collection('system_settings').doc(key).set({ value, updatedAt: now }, { merge: true })
    );

    await Promise.all(updatePromises);

    await db.collection('audit_logs').add({
      actionType: 'UPDATE',
      userId: context.auth.uid,
      userRole: claims.role || 'unknown',
      targetCollection: 'system_settings',
      targetDocumentId: 'bulk_update',
      beforeValue: null,
      afterValue: settings,
      timestamp: now,
    });

    return { message: 'System settings updated' };
  } catch (error) {
    functions.logger.error('updateSystemSettings error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to update system settings');
  }
});

export const getSystemSettings = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Authentication required');

    const snapshot = await db.collection('system_settings').get();
    const settings: Record<string, unknown> = {};
    snapshot.docs.forEach((doc) => {
      settings[doc.id] = doc.data();
    });

    return { settings };
  } catch (error) {
    functions.logger.error('getSystemSettings error', error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Failed to load system settings');
  }
});
