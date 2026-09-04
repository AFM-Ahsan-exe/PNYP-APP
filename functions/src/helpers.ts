import * as crypto from 'crypto';
import * as admin from 'firebase-admin';

export function hmacSha256(cnic: string, secret: string): string {
  return crypto.createHmac('sha256', secret).update(cnic).digest('hex');
}

export function generateMemberId(year: number): string {
  const sequence = crypto.randomInt(100000, 999999).toString();
  return `PYNP-${year}-${sequence}`;
}
export async function assignMemberId(
  db: admin.firestore.Firestore,
  year: number
): Promise<string> {
  const counterRef = db.collection('system_counters').doc(`members_${year}`);
  const sequence = await db.runTransaction(async (tx) => {
    const snap = await tx.get(counterRef);
    const current = (snap.data()?.count as number | undefined) ?? 0;
    const next = current + 1;
    tx.set(counterRef, { count: next }, { merge: true });
    return next;
  });
  return `PYNP-${year}-${sequence.toString().padStart(6, '0')}`;
}

export function computeAge(dateOfBirth: admin.firestore.Timestamp | undefined): number {
  if (!dateOfBirth) return 0;
  const dob = dateOfBirth.toDate();
  const today = new Date();
  let age = today.getFullYear() - dob.getFullYear();
  const monthDiff = today.getMonth() - dob.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
    age--;
  }
  return age;
}

export function validateCnicFormat(cnic: string): boolean {
  const digits = cnic.replace(/-/g, '');
  return /^\d{13}$/.test(digits);
}

const ROLE_HIERARCHY = [
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
export function isAtLeastRole(
  minimumRole: string,
  claims: Record<string, unknown>,
): boolean {
  const role = claims.role as string | undefined;

  if (!role) {
    return false;
  }

  const callerIndex =
    ROLE_HIERARCHY.indexOf(role);

  const requiredIndex =
    ROLE_HIERARCHY.indexOf(minimumRole);

  if (
    callerIndex === -1 ||
    requiredIndex === -1
  ) {
    return false;
  }

  return callerIndex >= requiredIndex;
}

export function normalizeCnic(cnic: string): string {
  return cnic.replace(/\D/g, '');
}

/**
 * Normalizes a date value received from the client into a Firestore
 * Timestamp. Client-side `cloud_firestore` Timestamp objects cannot be
 * JSON-encoded (no toJson()), so any date sent through a callable
 * function necessarily arrives as an ISO string (or, if it does arrive
 * as {seconds, nanoseconds}, that shape is handled too). Comparing a
 * Timestamp-typed Firestore field against a raw string never throws -
 * it just silently matches nothing - so this conversion is required
 * wherever a date is used in a query or stored into a Timestamp field.
 */
export function toFirestoreTimestamp(
  value: unknown
): admin.firestore.Timestamp | undefined {
  if (value == null) return undefined;
  if (value instanceof admin.firestore.Timestamp) return value;
  if (typeof value === 'string') {
    const parsed = new Date(value);
    if (isNaN(parsed.getTime())) return undefined;
    return admin.firestore.Timestamp.fromDate(parsed);
  }
  if (typeof value === 'object' && value !== null && 'seconds' in value) {
    const v = value as { seconds: number; nanoseconds?: number };
    if (typeof v.seconds === 'number') {
      return new admin.firestore.Timestamp(v.seconds, v.nanoseconds ?? 0);
    }
  }
  return undefined;
}

/**
 * Writes a compact entry to `activity_logs`, the collection the Flutter
 * app's admin dashboard "Recent Activity" widget reads from
 * (DashboardRepositoryImpl.activityCollection). Previously nothing ever
 * wrote to this collection - all real audit data went to the separate,
 * detailed `audit_logs` collection instead - so the dashboard widget was
 * always empty. The one place that did try to write to `activity_logs`
 * was a client-side call gated by a security rule requiring admin
 * privileges, called by brand-new (non-admin) registrants, so it always
 * failed silently. Writing here, from trusted server code, fixes that.
 */
export async function logActivity(
  db: admin.firestore.Firestore,
  entry: {
    title: string;
    type: 'member' | 'volunteer' | 'coordinator' | 'application' | 'opportunity' | 'general';
    subtitle?: string | null;
    userId?: string;
  }
): Promise<void> {
  try {
    await db.collection('activity_logs').add({
      title: entry.title,
      subtitle: entry.subtitle ?? null,
      type: entry.type,
      timestamp: admin.firestore.Timestamp.now(),
      ...(entry.userId ? { userId: entry.userId } : {}),
    });
  } catch (error) {
    // Never let the dashboard feed break the primary action.
    console.error('logActivity failed', error);
  }
  
}
