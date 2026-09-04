import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {isAtLeastRole, logActivity, assignMemberId} from './helpers';

const db = admin.firestore();
const auth = admin.auth();

export const updateUserRole = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const callerUid = context.auth.uid;
    const callerToken = await auth.getUser(callerUid);
    const callerClaims = callerToken.customClaims || {};

    if (!isAtLeastRole('president', callerClaims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only presidents and super admins can update roles',
      );
    }

    const {uid, role} = data as {
      uid: string;
      role: string;
    };

    if (!uid || !role) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'uid and role are required',
      );
    }

    const validRoles = [
      'member',
      'district_coordinator',
      'regional_coordinator',
      'content_manager',
      'opportunity_manager',
      'admin',
      'national_admin',
      'president',
      'super_admin',
    ];

    if (!validRoles.includes(role)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid role',
      );
    }

    if (callerUid === uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You cannot modify your own account',
      );
    }

    const targetUser = await auth.getUser(uid);
    const previousClaims = targetUser.customClaims || {};

    const hierarchy = [
      'member',
      'district_coordinator',
      'regional_coordinator',
      'content_manager',
      'opportunity_manager',
      'admin',
      'national_admin',
      'president',
      'super_admin',
    ];

    const callerRole =
        (callerClaims.role as string | undefined) ?? 'member';

    const callerIndex = hierarchy.indexOf(callerRole);
    const targetIndex = hierarchy.indexOf(role);

    if (callerIndex === -1 || targetIndex === -1) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Invalid role hierarchy',
      );
    }

    if (targetIndex >= callerIndex) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You cannot assign a role equal to or higher than your own role',
      );
    }

    const newAdminClaim =
        targetIndex >= hierarchy.indexOf('district_coordinator');

    await auth.setCustomUserClaims(uid, {
      ...previousClaims,
      role,
      admin: newAdminClaim,
    });

    const now = admin.firestore.Timestamp.now();

    await db.collection('users').doc(uid).update({
      role,
      updatedAt: now,
    });

    await db.collection('audit_logs').add({
      actionType: 'UPDATE',
      userId: callerUid,
      userRole: callerClaims.role || 'unknown',
      targetCollection: 'users',
      targetDocumentId: uid,
      beforeValue: {
        role: previousClaims.role,
        admin: previousClaims.admin,
      },
      afterValue: {
        role,
        admin: newAdminClaim,
      },
      timestamp: now,
    });

    await logActivity(db, {
      title: 'Role updated',
      type: 'coordinator',
      subtitle: targetUser.email
        ? `${targetUser.email} -> ${role}`
        : role,
      userId: uid,
    });

    return {
      message: 'Role updated successfully',
    };
  } catch (error) {
    functions.logger.error('updateUserRole error', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to update role',
    );
  }
});

export const getAuditLogs = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};

    if (!isAtLeastRole('national_admin', claims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only national admins and above can view audit logs',
      );
    }

    const {
      startDate,
      endDate,
      actionType,
      userId,
      limit: logLimit,
    } = data as {
      startDate?:
          | admin.firestore.Timestamp
          | string
          | {seconds: number; nanoseconds?: number};
      endDate?:
          | admin.firestore.Timestamp
          | string
          | {seconds: number; nanoseconds?: number};
      actionType?: string;
      userId?: string;
      limit?: number;
    };

    const toTimestamp = (
      value:
          | admin.firestore.Timestamp
          | string
          | {seconds: number; nanoseconds?: number}
          | undefined,
    ): admin.firestore.Timestamp | undefined => {
      if (value == null) {
        return undefined;
      }

      if (value instanceof admin.firestore.Timestamp) {
        return value;
      }

      if (typeof value === 'string') {
        const date = new Date(value);

        if (Number.isNaN(date.getTime())) {
          return undefined;
        }

        return admin.firestore.Timestamp.fromDate(date);
      }

      if (
        typeof value === 'object' &&
        typeof value.seconds === 'number'
      ) {
        return new admin.firestore.Timestamp(
          value.seconds,
          value.nanoseconds ?? 0,
        );
      }

      return undefined;
    };

    const startTimestamp = toTimestamp(startDate);
    const endTimestamp = toTimestamp(endDate);

    let query: admin.firestore.Query =
  db.collection('audit_logs');

if (startTimestamp) {
  query = query.where(
    'timestamp',
    '>=',
    startTimestamp,
  );
}

if (endTimestamp) {
  query = query.where(
    'timestamp',
    '<=',
    endTimestamp,
  );
}
    

    if (actionType) {
      query = query.where(
        'actionType',
        '==',
        actionType,
      );
    }

    if (userId) {
      query = query.where(
        'userId',
        '==',
        userId,
      );
    }

    const snapshot = await query
        .orderBy('timestamp', 'desc')
        .limit(logLimit ?? 200)
        .get();

    const logs = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return {logs};
  } catch (error) {
    functions.logger.error('getAuditLogs error', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to load audit logs',
    );
  }
});

export const updateSystemSettings =
    functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};

    if (!isAtLeastRole('national_admin', claims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only national admins and above can update system settings',
      );
    }

    const {settings} = data as {
      settings: Record<string, unknown>;
    };

    if (!settings || typeof settings !== 'object') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'settings object is required',
      );
    }

    const allowedKeys = [
      'maintenance_mode',
      'registration_enabled',
      'max_file_size_mb',
      'allowed_file_types',
      'support_email',
      'organization_name',
      'terms_version',
      'privacy_version',
    ];

    const invalidKeys = Object.keys(settings).filter(
      (key) => !allowedKeys.includes(key),
    );

    if (invalidKeys.length > 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Invalid setting keys: ${invalidKeys.join(', ')}`,
      );
    }

    const now = admin.firestore.Timestamp.now();

    const updatePromises = Object.entries(settings).map(
      ([key, value]) =>
        db
            .collection('system_settings')
            .doc(key)
            .set(
              {
                value,
                updatedAt: now,
              },
              {merge: true},
            ),
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

    return {
      message: 'System settings updated',
    };
  } catch (error) {
    functions.logger.error(
      'updateSystemSettings error',
      error,
    );

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to update system settings',
    );
  }
});

export const getSystemSettings =
    functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};

    if (!isAtLeastRole('national_admin', claims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only national admins and above can view system settings',
      );
    }

    const snapshot = await db
        .collection('system_settings')
        .get();

    const settings: Record<string, unknown> = {};

    snapshot.docs.forEach((doc) => {
      settings[doc.id] = doc.data();
    });

    return {settings};
  } catch (error) {
    functions.logger.error(
      'getSystemSettings error',
      error,
    );

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to load system settings',
    );
  }
});

export const approveMember =
    functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const callerUid = context.auth.uid;
    const callerToken = await auth.getUser(callerUid);
    const claims = callerToken.customClaims || {};

    if (!isAtLeastRole('district_coordinator', claims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only district coordinators and above can approve members',
      );
    }

    const {uid, membershipType} = data as {
      uid: string;
      membershipType?: string;
    };

    if (!uid) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'uid is required',
      );
    }

    if (callerUid === uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You cannot modify your own account',
      );
    }

    const memberRef = db.collection('users').doc(uid);
    const member = await memberRef.get();

    if (!member.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'User not found',
      );
    }

    const now = admin.firestore.Timestamp.now();

    const updates: Record<string, unknown> = {
      status: 'approved',
      approvedAt: now,
      approvedBy: callerUid,
      updatedAt: now,
    };

    if (membershipType) {
      updates.membershipType = membershipType;
    }

    const membershipStartDate = now.toDate();

    updates.membershipStartDate =
        admin.firestore.Timestamp.fromDate(
          membershipStartDate,
        );

    updates.membershipExpiryDate =
        admin.firestore.Timestamp.fromDate(
          new Date(
            membershipStartDate.getFullYear() + 1,
            membershipStartDate.getMonth(),
            membershipStartDate.getDate(),
          ),
        );

    const existingMembershipId =
        member.data()?.membershipId as string | undefined;

    if (!existingMembershipId) {
      updates.membershipId = await assignMemberId(
        db,
        membershipStartDate.getFullYear(),
      );
    }

    await memberRef.update(updates);

    const pendingPayments = await db
        .collection('payments')
        .where('userId', '==', uid)
        .where('status', '==', 'pending')
        .get();

    if (!pendingPayments.empty) {
      const batch = db.batch();

      pendingPayments.docs.forEach((doc) => {
        batch.update(doc.ref, {
          status: 'verified',
          verifiedAt: now,
          verifiedBy: callerUid,
        });
      });

      await batch.commit();
    }

    await db.collection('audit_logs').add({
      actionType: 'APPROVE',
      userId: callerUid,
      userRole: claims.role || 'unknown',
      targetCollection: 'users',
      targetDocumentId: uid,
      beforeValue: {
        status: member.data()?.status,
      },
      afterValue: {
        status: 'approved',
        membershipType:
            membershipType ??
            member.data()?.membershipType,
      },
      timestamp: now,
    });

    await logActivity(db, {
      title: 'Member approved',
      type: 'application',
      subtitle:
          member.data()?.fullName ||
          member.data()?.email ||
          uid,
      userId: uid,
    });

    return {
      message: 'Member approved successfully',
      uid,
    };
  } catch (error) {
    functions.logger.error(
      'approveMember error',
      error,
    );

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to approve member',
    );
  }
});

export const rejectMember =
    functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const callerUid = context.auth.uid;
    const callerToken = await auth.getUser(callerUid);
    const claims = callerToken.customClaims || {};

    if (!isAtLeastRole('district_coordinator', claims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only district coordinators and above can reject members',
      );
    }

    const {uid, reason} = data as {
      uid: string;
      reason?: string;
    };

    if (!uid) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'uid is required',
      );
    }

    if (callerUid === uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You cannot modify your own account',
      );
    }

    const memberRef = db.collection('users').doc(uid);
    const member = await memberRef.get();

    if (!member.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'User not found',
      );
    }

    const now = admin.firestore.Timestamp.now();

    const updates: Record<string, unknown> = {
      status: 'rejected',
      updatedAt: now,
    };

    if (reason) {
      updates.rejectionReason = reason;
    }

    await memberRef.update(updates);

    const pendingPayments = await db
        .collection('payments')
        .where('userId', '==', uid)
        .where('status', '==', 'pending')
        .get();

    if (!pendingPayments.empty) {
      const batch = db.batch();

      pendingPayments.docs.forEach((doc) => {
        batch.update(doc.ref, {
          status: 'rejected',
          rejectedAt: now,
          rejectedBy: callerUid,
        });
      });

      await batch.commit();
    }

    await db.collection('audit_logs').add({
      actionType: 'REJECT',
      userId: callerUid,
      userRole: claims.role || 'unknown',
      targetCollection: 'users',
      targetDocumentId: uid,
      beforeValue: {
        status: member.data()?.status,
      },
      afterValue: {
        status: 'rejected',
        reason: reason ?? null,
      },
      timestamp: now,
    });

    await logActivity(db, {
      title: 'Member rejected',
      type: 'application',
      subtitle:
          member.data()?.fullName ||
          member.data()?.email ||
          uid,
      userId: uid,
    });

    return {
      message: 'Member rejected successfully',
      uid,
    };
  } catch (error) {
    functions.logger.error(
      'rejectMember error',
      error,
    );

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to reject member',
    );
  }
});

/**
 * Archive one user instead of permanently deleting them.
 *
 * The member record is retained for historical records,
 * audit requirements, and SRS data-retention requirements.
 *
 * - Disables Firebase Authentication account
 * - Revokes refresh tokens
 * - Preserves Firestore users/{uid}
 * - Changes status to "archived"
 * - Records archivedAt and archivedBy
 * - Creates an audit log
 *
 * Only super admins can perform this operation.
 *
 * The exported function name "deleteUser" is intentionally
 * preserved for compatibility with the existing client.
 */
export const deleteUser =
    functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const callerUid = context.auth.uid;
    const callerToken = await auth.getUser(callerUid);
    const claims = callerToken.customClaims || {};

    if (!isAtLeastRole('super_admin', claims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only super admins can archive users',
      );
    }

    const {uid} = data as {
      uid: string;
    };

    if (!uid) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'uid is required',
      );
    }

    if (uid === callerUid) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'You cannot archive your own account',
      );
    }

    const targetUser = await auth
        .getUser(uid)
        .catch(() => null);

    if (!targetUser) {
      throw new functions.https.HttpsError(
        'not-found',
        'User not found',
      );
    }

    const targetRole =
        (targetUser.customClaims?.role as string | undefined) ??
        'member';

    if (targetRole === 'super_admin') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Cannot archive another super admin',
      );
    }

    const userRef = db
        .collection('users')
        .doc(uid);

    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'User profile not found',
      );
    }

    const beforeValue = userDoc.data();

    const now = admin.firestore.Timestamp.now();

    // TASK 21: Disable the Auth account instead of deleting it.
    await auth.updateUser(uid, {
      disabled: true,
    });

    // TASK 21: Invalidate existing sessions.
    await auth.revokeRefreshTokens(uid);

    // TASK 21: Preserve the Firestore record and archive it.
    await userRef.update({
      status: 'archived',
      archivedAt: now,
      archivedBy: callerUid,
      updatedAt: now,
    });

    // TASK 21: Record the archive operation.
    await db.collection('audit_logs').add({
      actionType: 'ARCHIVE_USER',
      userId: callerUid,
      userRole: claims.role || 'unknown',
      targetCollection: 'users',
      targetDocumentId: uid,
      beforeValue,
      afterValue: {
        status: 'archived',
      },
      timestamp: now,
    });

    return {
      message: 'User archived successfully',
    };
  } catch (error) {
    functions.logger.error(
      'deleteUser error',
      error,
    );

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to archive user',
    );
  }
});

/**
 * Bulk archive users instead of permanently deleting them.
 *
 * The exported function name "bulkDeleteUsers" is intentionally
 * preserved for compatibility with the existing client.
 */
export const bulkDeleteUsers =
    functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const callerUid = context.auth.uid;
    const callerToken = await auth.getUser(callerUid);
    const claims = callerToken.customClaims || {};

    if (!isAtLeastRole('super_admin', claims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only super admins can archive users',
      );
    }

    const {userIds} = data as {
      userIds: string[];
    };

    if (
      !userIds ||
      !Array.isArray(userIds) ||
      userIds.length === 0
    ) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'userIds array is required',
      );
    }

    // Remove duplicate user IDs.
    const uniqueUserIds = [...new Set(userIds)];

    const targetUsers = await auth.getUsers(
      uniqueUserIds.map((id) => ({
        uid: id,
      })),
    );

    /*
     * Only users who:
     * - are not the caller
     * - are not super admins
     * are eligible for archival.
     */
    const eligibleUsers = targetUsers.users
        .filter((user) => user.uid !== callerUid)
        .filter((user) => {
          const role =
              (user.customClaims?.role as string | undefined) ??
              'member';

          return role !== 'super_admin';
        });

    if (eligibleUsers.length === 0) {
      return {
        message: 'No eligible users to archive',
        archivedCount: 0,
      };
    }

    const now = admin.firestore.Timestamp.now();

    const archivedIds: string[] = [];
    const failedIds: string[] = [];

    /*
     * TASK 22:
     * Archive every eligible user.
     *
     * There is NO auth.deleteUser().
     * There is NO Firestore document delete().
     */
    for (const user of eligibleUsers) {
      try {
        const userRef = db
            .collection('users')
            .doc(user.uid);

        const userDoc = await userRef.get();

        if (!userDoc.exists) {
          functions.logger.warn(
            'User profile not found while archiving',
            user.uid,
          );

          failedIds.push(user.uid);
          continue;
        }

        /*
         * TASK 22:
         * Disable Firebase Authentication account.
         */
        await auth.updateUser(user.uid, {
          disabled: true,
        });

        /*
         * TASK 22:
         * Revoke existing refresh tokens/sessions.
         */
        await auth.revokeRefreshTokens(user.uid);

        /*
         * TASK 22:
         * Preserve Firestore record and mark it archived.
         */
        await userRef.update({
          status: 'archived',
          archivedAt: now,
          archivedBy: callerUid,
          updatedAt: now,
        });

        archivedIds.push(user.uid);
      } catch (error) {
        functions.logger.warn(
          'Failed to archive user',
          user.uid,
          error,
        );

        failedIds.push(user.uid);
      }
    }

    /*
     * Audit the bulk archive operation.
     */
    if (archivedIds.length > 0) {
      await db.collection('audit_logs').add({
        actionType: 'ARCHIVE_USER',
        userId: callerUid,
        userRole: claims.role || 'unknown',
        targetCollection: 'users',
        targetDocumentId: 'bulk_archive',
        beforeValue: {
          userIds: uniqueUserIds,
        },
        afterValue: {
          status: 'archived',
          archivedCount: archivedIds.length,
          archivedUserIds: archivedIds,
          failedCount: failedIds.length,
          failedUserIds: failedIds,
        },
        timestamp: now,
      });
    }

    return {
      message: 'Bulk archive completed',
      archivedCount: archivedIds.length,
    };
  } catch (error) {
    functions.logger.error(
      'bulkDeleteUsers error',
      error,
    );

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to archive users',
    );
  }
});

export const getDashboardStats =
    functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};

    if (!isAtLeastRole('district_coordinator', claims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only district coordinators and above can view dashboard stats',
      );
    }

    const coordinatorRoles = [
      'admin',
      'district_coordinator',
      'regional_coordinator',
      'content_manager',
      'opportunity_manager',
      'national_admin',
      'president',
      'super_admin',
    ];

    const [
      totalMembersCount,
      pendingApplicationsCount,
      totalCoordinatorsCount,
      totalVolunteersCount,
      activeOpportunitiesCount,
    ] = await Promise.all([
      db
          .collection('users')
          .where('role', '==', 'member')
          .count()
          .get(),

      db
          .collection('users')
          .where('role', '==', 'member')
          .where('status', '==', 'pending')
          .count()
          .get(),

      db
          .collection('users')
          .where('role', 'in', coordinatorRoles)
          .count()
          .get(),

      db
          .collection('volunteers')
          .count()
          .get(),

      db
          .collection('opportunities')
          .where('status', '==', 'active')
          .count()
          .get(),
    ]);

    return {
      totalMembers: totalMembersCount.data().count,
      totalVolunteers: totalVolunteersCount.data().count,
      totalCoordinators: totalCoordinatorsCount.data().count,
      pendingApplications:
          pendingApplicationsCount.data().count,
      activeOpportunities:
          activeOpportunitiesCount.data().count,
    };
  } catch (error) {
    functions.logger.error(
      'getDashboardStats error',
      error,
    );

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to load dashboard stats',
    );
  }
});

export const getPendingMembers =
    functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const callerToken = await auth.getUser(context.auth.uid);
    const claims = callerToken.customClaims || {};

    if (!isAtLeastRole('district_coordinator', claims)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only district coordinators and above can view members',
      );
    }

    const {status} = data as {
      status?: string;
    };

    let query: admin.firestore.Query =
        db.collection('users');

    if (status && status !== 'all') {
      query = query.where(
        'status',
        '==',
        status,
      );
    }

    const snapshot = await query
        .orderBy('createdAt', 'desc')
        .limit(100)
        .get();

    const members = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    return {
      members,
    };
  } catch (error) {
    functions.logger.error(
      'getPendingMembers error',
      error,
    );

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to load members',
    );
  }
});

export const getMemberDirectory =
    functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const {query: searchQuery} = data as {
      query?: string;
    };

    const query: admin.firestore.Query =
        db
            .collection('users')
            .where('status', '==', 'approved');

    const snapshot = await query
        .limit(100)
        .get();

    let members = snapshot.docs.map((doc) => {
      const d = doc.data();

      return {
        id: doc.id,
        fullName: d.fullName || '',
        //email: d.email || '',
        province: d.province || '',
        district: d.district || '',
        city: d.city || '',
        membershipType: d.membershipType || '',
        membershipId: d.membershipId || '',
        profilePictureUrl: d.profilePictureUrl || '',
        status: d.status || 'pending',
        role: d.role || 'member',
      };
    });

    if (
      searchQuery &&
      searchQuery.trim().length > 0
    ) {
      const lower = searchQuery.toLowerCase();

      members = members.filter(
        (member: Record<string, unknown>) => {
          const name =
              ((member['fullName'] as string) || '')
                  .toLowerCase();

          const email =
              ((member['email'] as string) || '')
                  .toLowerCase();

          const city =
              ((member['city'] as string) || '')
                  .toLowerCase();

          const district =
              ((member['district'] as string) || '')
                  .toLowerCase();

          const province =
              ((member['province'] as string) || '')
                  .toLowerCase();

          return (
            name.includes(lower) ||
            email.includes(lower) ||
            city.includes(lower) ||
            district.includes(lower) ||
            province.includes(lower)
          );
        },
      );
    }

    return {
      members,
    };
  } catch (error) {
    functions.logger.error(
      'getMemberDirectory error',
      error,
    );

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'Failed to load member directory',
    );
  }
});