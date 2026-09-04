const { cert, initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const serviceAccount = require('./service-account.json');
const uid = process.argv[2];

if (!uid) {
  console.error('Usage: node server/set-admin.js FIREBASE_UID');
  process.exit(1);
}

initializeApp({
  credential: cert(serviceAccount),
});

async function grantAdminAccess() {
  const auth = getAuth();
  const firestore = getFirestore();

  const user = await auth.getUser(uid);
  const existingClaims = user.customClaims ?? {};

  // Mark this admin account's email as verified.
  await auth.updateUser(uid, {
    emailVerified: true,
  });

  // This script is the ONLY way to create the very first privileged
  // account on a fresh project - it already requires direct filesystem
  // access to the Firebase service-account private key, the single most
  // trusted credential in the whole system, so granting the top role
  // tier here is consistent with its purpose, not a security weakening.
  // It previously granted role: 'admin', which sits BELOW national_admin
  // in the hierarchy (helpers.ts#isAtLeastRole) - meaning the very first
  // admin could never pass the national_admin+ checks on getAuditLogs/
  // getSystemSettings, nor the president+ check on updateUserRole to
  // promote anyone else. That's a real chicken-and-egg lockout on a
  // fresh deployment: nobody could ever reach those roles at all.
  await auth.setCustomUserClaims(uid, {
    ...existingClaims,
    admin: true,
    role: 'super_admin',
  });

  // Ensure the Firestore profile is approved as admin.
  await firestore.collection('users').doc(uid).set({
    uid,
    email: user.email?.toLowerCase() ?? '',
    role: 'super_admin',
    status: 'approved',
    approvedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`Admin access granted and email verified for ${user.email ?? uid}`);
}

grantAdminAccess().catch((error) => {
  console.error(error.message);
  process.exit(1);
});