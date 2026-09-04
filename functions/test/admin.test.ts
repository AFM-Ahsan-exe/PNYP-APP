jest.mock('firebase-admin', () => {
  const mockTimestamp = {
    now: jest.fn(() => ({ 
      seconds: 1000000, 
      nanoseconds: 0,
      toDate: () => new Date(1000000000),
    })),
    fromDate: jest.fn((date: Date) => ({
      seconds: Math.floor(date.getTime() / 1000),
      nanoseconds: (date.getTime() % 1000) * 1000000,
      toDate: () => new Date(date.getTime()),
    })),
  };

  const createMockDoc = () => ({
    get: jest.fn(),
    update: jest.fn(),
    set: jest.fn(),
    delete: jest.fn(),
  });

  const createMockCollection = () => {
    const docs = new Map<string, ReturnType<typeof createMockDoc>>();
    const collection: any = {
      doc: jest.fn((id: string) => {
        if (!docs.has(id)) {
          docs.set(id, createMockDoc());
        }
        return docs.get(id)!;
      }),
      add: jest.fn(),
      get: jest.fn(),
      where: jest.fn(() => collection),
      orderBy: jest.fn(() => collection),
      limit: jest.fn(() => collection),
    };
    return collection;
  };

  let firestoreInstance: ReturnType<typeof createMockCollection> | null = null;
  let authInstance: ReturnType<typeof createMockAuth> | null = null;

  const mockFirestore = jest.fn(() => {
    if (!firestoreInstance) {
      firestoreInstance = createMockCollection();
    }
    return {
      collection: jest.fn(() => firestoreInstance!),
    };
  });

  const createMockAuth = () => ({
    getUser: jest.fn(),
    getUsers: jest.fn(),
    setCustomUserClaims: jest.fn(),
  });

  const mockAuth = jest.fn(() => {
    if (!authInstance) {
      authInstance = createMockAuth();
    }
    return authInstance;
  });

  return {
    initializeApp: jest.fn(),
    firestore: Object.assign(mockFirestore, { Timestamp: mockTimestamp }),
    auth: mockAuth,
  };
});

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import {
  approveMember,
  rejectMember,
  updateUserRole,
  bulkDeleteUsers,
  getAuditLogs,
  updateSystemSettings,
  getSystemSettings,
} from '../src/admin';

jest.spyOn(functions.logger, 'error').mockImplementation(() => {});
jest.spyOn(functions.logger, 'warn').mockImplementation(() => {});

const mockUserRecord = (uid: string, customClaims: Record<string, unknown> = {}) => ({
  uid,
  customClaims,
});

const mockDocSnapshot = (exists: boolean, data: Record<string, unknown> = {}) => ({
  exists,
  data: jest.fn(() => (exists ? data : undefined)),
});

const mockQuerySnapshot = (docs: Array<{ id: string; data: Record<string, unknown> }>) => ({
  docs: docs.map((d) => ({
    id: d.id,
    data: jest.fn(() => d.data),
  })),
});

beforeEach(() => {
  jest.clearAllMocks();
});

describe('approveMember', () => {
  const callerUid = 'caller-uid';
  const targetUid = 'target-uid';

  const baseContext = (role: string) => ({
    auth: { uid: callerUid },
  });

  const baseData = (uid: string) => ({ uid });

  beforeEach(() => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'district_coordinator' }));
  });

  it('requires authentication', async () => {
    await expect(approveMember.run!(baseData(targetUid), { auth: undefined } as any)).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('requires district_coordinator+', async () => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'member' }));
    await expect(approveMember.run!(baseData(targetUid), baseContext('member'))).rejects.toMatchObject({
      code: 'permission-denied',
    });
  });

  it('rejects self-modification', async () => {
    await expect(approveMember.run!(baseData(callerUid), baseContext('district_coordinator'))).rejects.toMatchObject({
      code: 'permission-denied',
      message: 'You cannot modify your own account',
    });
  });

  it('rejects if target user not found', async () => {
    const db = admin.firestore() as any;
    db.collection('users').doc(targetUid).get.mockResolvedValue(mockDocSnapshot(false));
    await expect(approveMember.run!(baseData(targetUid), baseContext('district_coordinator'))).rejects.toMatchObject({
      code: 'not-found',
    });
  });

  it('updates user status and writes audit log', async () => {
    const db = admin.firestore() as any;
    db.collection('users').doc(targetUid).get.mockResolvedValue(
      mockDocSnapshot(true, { status: 'pending', membershipType: 'individual' })
    );
    db.collection('users').doc(targetUid).update.mockResolvedValue(undefined);
    db.collection('audit_logs').add.mockResolvedValue(undefined);

    const result = await approveMember.run!(baseData(targetUid), baseContext('district_coordinator'));

    expect(result).toEqual({ message: 'Member approved successfully', uid: targetUid });
    expect(db.collection('users').doc(targetUid).update).toHaveBeenCalledWith(
      expect.objectContaining({
        status: 'approved',
        approvedBy: callerUid,
        membershipStartDate: expect.anything(),
        membershipExpiryDate: expect.anything(),
      })
    );
    expect(db.collection('audit_logs').add).toHaveBeenCalledWith(
      expect.objectContaining({
        actionType: 'APPROVE',
        userId: callerUid,
        targetDocumentId: targetUid,
        afterValue: expect.objectContaining({ status: 'approved' }),
      })
    );
  });

  it('passes membershipType when provided', async () => {
    const db = admin.firestore() as any;
    db.collection('users').doc(targetUid).get.mockResolvedValue(
      mockDocSnapshot(true, { status: 'pending' })
    );
    db.collection('users').doc(targetUid).update.mockResolvedValue(undefined);
    db.collection('audit_logs').add.mockResolvedValue(undefined);

    await approveMember.run!({ uid: targetUid, membershipType: 'corporate' }, baseContext('district_coordinator'));

    expect(db.collection('users').doc(targetUid).update).toHaveBeenCalledWith(
      expect.objectContaining({
        membershipType: 'corporate',
      })
    );
    expect(db.collection('audit_logs').add).toHaveBeenCalledWith(
      expect.objectContaining({
        afterValue: expect.objectContaining({ membershipType: 'corporate' }),
      })
    );
  });
});

describe('rejectMember', () => {
  const callerUid = 'caller-uid';
  const targetUid = 'target-uid';

  const baseContext = (role: string) => ({
    auth: { uid: callerUid },
  });

  const baseData = (uid: string) => ({ uid });

  beforeEach(() => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'district_coordinator' }));
  });

  it('requires authentication', async () => {
    await expect(rejectMember.run!(baseData(targetUid), { auth: undefined } as any)).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('requires district_coordinator+', async () => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'member' }));
    await expect(rejectMember.run!(baseData(targetUid), baseContext('member'))).rejects.toMatchObject({
      code: 'permission-denied',
    });
  });

  it('rejects self-modification', async () => {
    await expect(rejectMember.run!(baseData(callerUid), baseContext('district_coordinator'))).rejects.toMatchObject({
      code: 'permission-denied',
      message: 'You cannot modify your own account',
    });
  });

  it('rejects if target user not found', async () => {
    const db = admin.firestore() as any;
    db.collection('users').doc(targetUid).get.mockResolvedValue(mockDocSnapshot(false));
    await expect(rejectMember.run!(baseData(targetUid), baseContext('district_coordinator'))).rejects.toMatchObject({
      code: 'not-found',
    });
  });

  it('updates status with reason and writes audit log', async () => {
    const db = admin.firestore() as any;
    db.collection('users').doc(targetUid).get.mockResolvedValue(
      mockDocSnapshot(true, { status: 'pending' })
    );
    db.collection('users').doc(targetUid).update.mockResolvedValue(undefined);
    db.collection('audit_logs').add.mockResolvedValue(undefined);

    const result = await rejectMember.run!({ uid: targetUid, reason: 'Invalid docs' }, baseContext('district_coordinator'));

    expect(result).toEqual({ message: 'Member rejected successfully', uid: targetUid });
    expect(db.collection('users').doc(targetUid).update).toHaveBeenCalledWith(
      expect.objectContaining({
        status: 'rejected',
        rejectionReason: 'Invalid docs',
      })
    );
    expect(db.collection('audit_logs').add).toHaveBeenCalledWith(
      expect.objectContaining({
        actionType: 'REJECT',
        targetDocumentId: targetUid,
        afterValue: expect.objectContaining({ status: 'rejected', reason: 'Invalid docs' }),
      })
    );
  });

  it('rejects without reason', async () => {
    const db = admin.firestore() as any;
    db.collection('users').doc(targetUid).get.mockResolvedValue(
      mockDocSnapshot(true, { status: 'pending' })
    );
    db.collection('users').doc(targetUid).update.mockResolvedValue(undefined);
    db.collection('audit_logs').add.mockResolvedValue(undefined);

    await rejectMember.run!(baseData(targetUid), baseContext('district_coordinator'));

    expect(db.collection('users').doc(targetUid).update).toHaveBeenCalledWith(
      expect.objectContaining({
        status: 'rejected',
      })
    );
    expect(db.collection('audit_logs').add).toHaveBeenCalledWith(
      expect.objectContaining({
        afterValue: expect.objectContaining({ status: 'rejected', reason: null }),
      })
    );
  });
});

describe('updateUserRole', () => {
  const callerUid = 'caller-uid';
  const targetUid = 'target-uid';

  const baseContext = (role: string) => ({
    auth: { uid: callerUid },
  });

  beforeEach(() => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'president' }));
    (admin.auth() as any).getUser.mockImplementation((uid: string) =>
      Promise.resolve(mockUserRecord(uid, { role: uid === callerUid ? 'president' : 'member' }))
    );
  });

  it('requires authentication', async () => {
    await expect(updateUserRole.run!({ uid: targetUid, role: 'district_coordinator' }, { auth: undefined } as any)).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('requires president+', async () => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'national_admin' }));
    await expect(updateUserRole.run!({ uid: targetUid, role: 'district_coordinator' }, baseContext('national_admin'))).rejects.toMatchObject({
      code: 'permission-denied',
    });
  });

  it('validates missing uid', async () => {
    await expect(updateUserRole.run!({ role: 'district_coordinator' }, baseContext('president'))).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });

  it('validates missing role', async () => {
    await expect(updateUserRole.run!({ uid: targetUid }, baseContext('president'))).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });

  it('validates role against allowed list', async () => {
    await expect(updateUserRole.run!({ uid: targetUid, role: 'hacker' }, baseContext('president'))).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });

  it('blocks self-promotion', async () => {
    await expect(updateUserRole.run!({ uid: callerUid, role: 'super_admin' }, baseContext('president'))).rejects.toMatchObject({
      code: 'permission-denied',
      message: 'You cannot modify your own account',
    });
  });

  it('updates custom claims AND Firestore users.role field', async () => {
    const db = admin.firestore() as any;
    db.collection('users').doc(targetUid).update.mockResolvedValue(undefined);
    db.collection('audit_logs').add.mockResolvedValue(undefined);

    await updateUserRole.run!({ uid: targetUid, role: 'district_coordinator', admin: true }, baseContext('president'));

    expect(admin.auth().setCustomUserClaims).toHaveBeenCalledWith(targetUid, {
      role: 'district_coordinator',
      admin: true,
    });
    expect(db.collection('users').doc(targetUid).update).toHaveBeenCalledWith(
      expect.objectContaining({
        role: 'district_coordinator',
        updatedAt: expect.anything(),
      })
    );
  });

  it('sets admin claim automatically for district_coordinator+', async () => {
    const db = admin.firestore() as any;
    db.collection('users').doc(targetUid).update.mockResolvedValue(undefined);
    db.collection('audit_logs').add.mockResolvedValue(undefined);

    await updateUserRole.run!({ uid: targetUid, role: 'district_coordinator' }, baseContext('president'));

    expect(admin.auth().setCustomUserClaims).toHaveBeenCalledWith(targetUid, {
      role: 'district_coordinator',
      admin: true,
    });
  });

  it('does not set admin claim for member role', async () => {
    const db = admin.firestore() as any;
    db.collection('users').doc(targetUid).update.mockResolvedValue(undefined);
    db.collection('audit_logs').add.mockResolvedValue(undefined);

    await updateUserRole.run!({ uid: targetUid, role: 'member' }, baseContext('president'));

    expect(admin.auth().setCustomUserClaims).toHaveBeenCalledWith(targetUid, {
      role: 'member',
      admin: false,
    });
  });

  it('writes audit log with before and after values', async () => {
    const db = admin.firestore() as any;
    db.collection('users').doc(targetUid).update.mockResolvedValue(undefined);
    db.collection('audit_logs').add.mockResolvedValue(undefined);

    await updateUserRole.run!({ uid: targetUid, role: 'national_admin' }, baseContext('president'));

    expect(db.collection('audit_logs').add).toHaveBeenCalledWith(
      expect.objectContaining({
        actionType: 'UPDATE',
        userId: callerUid,
        targetDocumentId: targetUid,
        beforeValue: expect.objectContaining({ role: 'member', admin: undefined }),
        afterValue: expect.objectContaining({ role: 'national_admin', admin: true }),
      })
    );
  });
});

describe('bulkDeleteUsers', () => {
  const callerUid = 'caller-uid';

  const baseContext = (role: string) => ({
    auth: { uid: callerUid },
  });

  beforeEach(() => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'super_admin' }));
  });

  it('requires authentication', async () => {
    await expect(bulkDeleteUsers.run!({ userIds: ['a'] }, { auth: undefined } as any)).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('requires super_admin+', async () => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'president' }));
    await expect(bulkDeleteUsers.run!({ userIds: ['a'] }, baseContext('president'))).rejects.toMatchObject({
      code: 'permission-denied',
    });
  });

  it('blocks self-deletion', async () => {
    (admin.auth() as any).getUsers.mockResolvedValue({
      users: [
        mockUserRecord(callerUid, { role: 'super_admin' }),
        mockUserRecord('user-2', { role: 'member' }),
      ],
    });

    const db = admin.firestore() as any;
    db.collection('users').doc('user-2').delete.mockResolvedValue(undefined);
    db.collection('audit_logs').add.mockResolvedValue(undefined);

    const result = await bulkDeleteUsers.run!({ userIds: [callerUid, 'user-2'] }, baseContext('super_admin'));

    expect(result).toEqual({ message: 'Bulk delete completed', deletedCount: 1 });
    expect(db.collection('users').doc(callerUid).delete).not.toHaveBeenCalled();
    expect(db.collection('users').doc('user-2').delete).toHaveBeenCalled();
  });

  it('blocks deleting super_admin targets', async () => {
    (admin.auth() as any).getUsers.mockResolvedValue({
      users: [
        mockUserRecord('admin-1', { role: 'super_admin' }),
        mockUserRecord('user-2', { role: 'member' }),
      ],
    });

    const db = admin.firestore() as any;
    db.collection('users').doc('user-2').delete.mockResolvedValue(undefined);
    db.collection('audit_logs').add.mockResolvedValue(undefined);

    const result = await bulkDeleteUsers.run!({ userIds: ['admin-1', 'user-2'] }, baseContext('super_admin'));

    expect(result).toEqual({ message: 'Bulk delete completed', deletedCount: 1 });
    expect(db.collection('users').doc('admin-1').delete).not.toHaveBeenCalled();
  });

  it('deletes eligible users and writes audit log', async () => {
    (admin.auth() as any).getUsers.mockResolvedValue({
      users: [
        mockUserRecord('user-1', { role: 'member' }),
        mockUserRecord('user-2', { role: 'member' }),
      ],
    });

    const db = admin.firestore() as any;
    db.collection('users').doc('user-1').delete.mockResolvedValue(undefined);
    db.collection('users').doc('user-2').delete.mockResolvedValue(undefined);
    db.collection('audit_logs').add.mockResolvedValue(undefined);

    const result = await bulkDeleteUsers.run!({ userIds: ['user-1', 'user-2'] }, baseContext('super_admin'));

    expect(result).toEqual({ message: 'Bulk delete completed', deletedCount: 2 });
    expect(db.collection('audit_logs').add).toHaveBeenCalledWith(
      expect.objectContaining({
        actionType: 'DELETE',
        userId: callerUid,
        afterValue: { deletedCount: 2 },
      })
    );
  });
});

describe('getAuditLogs', () => {
  const callerUid = 'caller-uid';

  const baseContext = (role: string) => ({
    auth: { uid: callerUid },
  });

  beforeEach(() => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'national_admin' }));
  });

  it('requires authentication', async () => {
    await expect(getAuditLogs.run!({}, { auth: undefined } as any)).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('requires national_admin+', async () => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'district_coordinator' }));
    await expect(getAuditLogs.run!({}, baseContext('district_coordinator'))).rejects.toMatchObject({
      code: 'permission-denied',
    });
  });

  it('supports filters', async () => {
    const db = admin.firestore() as any;
    db.collection('audit_logs').get.mockResolvedValue(
      mockQuerySnapshot([
        { id: 'log-1', data: { actionType: 'UPDATE', userId: 'user-1' } },
      ])
    );

    const result = await getAuditLogs.run!(
      {
        startDate: { seconds: 1000, nanoseconds: 0 } as any,
        endDate: { seconds: 2000, nanoseconds: 0 } as any,
        actionType: 'UPDATE',
        userId: 'user-1',
      },
      baseContext('national_admin')
    );

    expect(db.collection('audit_logs').where).toHaveBeenCalledWith('timestamp', '>=', expect.anything());
    expect(db.collection('audit_logs').where).toHaveBeenCalledWith('timestamp', '<=', expect.anything());
    expect(db.collection('audit_logs').where).toHaveBeenCalledWith('actionType', '==', 'UPDATE');
    expect(db.collection('audit_logs').where).toHaveBeenCalledWith('userId', '==', 'user-1');
    expect(result).toEqual({
      logs: [{ id: 'log-1', actionType: 'UPDATE', userId: 'user-1' }],
    });
  });

  it('respects limit parameter', async () => {
    const db = admin.firestore() as any;
    db.collection('audit_logs').limit.mockReturnThis();

    await getAuditLogs.run!({ limit: 10 }, baseContext('national_admin'));

    expect(db.collection('audit_logs').limit).toHaveBeenCalledWith(10);
  });

  it('defaults limit to 200', async () => {
    const db = admin.firestore() as any;
    db.collection('audit_logs').limit.mockReturnThis();

    await getAuditLogs.run!({}, baseContext('national_admin'));

    expect(db.collection('audit_logs').limit).toHaveBeenCalledWith(200);
  });
});

describe('updateSystemSettings', () => {
  const callerUid = 'caller-uid';

  const baseContext = (role: string) => ({
    auth: { uid: callerUid },
  });

  beforeEach(() => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'super_admin' }));
  });

  it('requires authentication', async () => {
    await expect(updateSystemSettings.run!({ settings: {} }, { auth: undefined } as any)).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('requires super_admin', async () => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'national_admin' }));
    await expect(updateSystemSettings.run!({ settings: {} }, baseContext('national_admin'))).rejects.toMatchObject({
      code: 'permission-denied',
    });
  });

  it('validates allowed keys only', async () => {
    await expect(
      updateSystemSettings.run!({ settings: { invalid_key: 'value', maintenance_mode: true } }, baseContext('super_admin'))
    ).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });

  it('rejects invalid keys', async () => {
    const error = await updateSystemSettings.run!(
      { settings: { maintenance_mode: true, evil_key: 'x' } },
      baseContext('super_admin')
    ).catch((e: any) => e);

    expect(error.code).toBe('invalid-argument');
    expect(error.message).toContain('evil_key');
  });

  it('writes audit log', async () => {
    const db = admin.firestore() as any;
    db.collection('system_settings').doc('maintenance_mode').set.mockResolvedValue(undefined);
    db.collection('audit_logs').add.mockResolvedValue(undefined);

    await updateSystemSettings.run!({ settings: { maintenance_mode: true } }, baseContext('super_admin'));

    expect(db.collection('system_settings').doc('maintenance_mode').set).toHaveBeenCalledWith(
      { value: true, updatedAt: expect.anything() },
      { merge: true }
    );
    expect(db.collection('audit_logs').add).toHaveBeenCalledWith(
      expect.objectContaining({
        actionType: 'UPDATE',
        targetCollection: 'system_settings',
      })
    );
  });
});

describe('getSystemSettings', () => {
  const callerUid = 'caller-uid';

  const baseContext = (role: string) => ({
    auth: { uid: callerUid },
  });

  beforeEach(() => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'member' }));
  });

  it('requires authentication', async () => {
    await expect(getSystemSettings.run!({}, { auth: undefined } as any)).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('requires national_admin+', async () => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'member' }));
    await expect(getSystemSettings.run!({}, baseContext('member'))).rejects.toMatchObject({
      code: 'permission-denied',
    });
  });

  it('returns all settings', async () => {
    (admin.auth() as any).getUser.mockResolvedValue(mockUserRecord(callerUid, { role: 'national_admin' }));
    const db = admin.firestore() as any;
    db.collection('system_settings').get.mockResolvedValue(
      mockQuerySnapshot([
        { id: 'maintenance_mode', data: { value: true, updatedAt: expect.anything() } },
        { id: 'registration_enabled', data: { value: true, updatedAt: expect.anything() } },
      ])
    );

    const result = await getSystemSettings.run!({}, baseContext('national_admin'));

    expect(result).toEqual({
      settings: {
        maintenance_mode: { value: true, updatedAt: expect.anything() },
        registration_enabled: { value: true, updatedAt: expect.anything() },
      },
    });
  });
});
