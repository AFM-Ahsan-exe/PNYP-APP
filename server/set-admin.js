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
  const user = await getAuth().getUser(uid);
  const existingClaims = user.customClaims ?? {};

  await getAuth().setCustomUserClaims(uid, {
    ...existingClaims,
    admin: true,
  });
  await getFirestore().collection('users').doc(uid).set({
    uid,
    email: user.email?.toLowerCase() ?? '',
    role: 'admin',
    status: 'approved',
    approvedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`Admin access granted to ${user.email ?? uid}`);
}

grantAdminAccess().catch((error) => {
  console.error(error.message);
  process.exit(1);
});