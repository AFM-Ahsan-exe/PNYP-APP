require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');

const serviceAccount = require('./service-account.json');

initializeApp({
  credential: cert(serviceAccount),
});

const app = express();
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

async function writeAuditLog({ action, targetUid, actorUid, details = {} }) {
  await getFirestore().collection('audit_logs').add({
    actionType: action,
    actorUid,
    actorRole: 'admin',
    targetCollection: 'users',
    targetDocument: targetUid,
    details,
    timestamp: FieldValue.serverTimestamp(),
  });
}

async function requireAdmin(req, res, next) {
  const authorization = req.headers.authorization ?? '';
  const token = authorization.startsWith('Bearer ')
    ? authorization.substring(7)
    : null;

  if (!token) return res.status(401).json({ error: 'Missing ID token' });

  try {
    const decodedToken = await getAuth().verifyIdToken(token);
    if (decodedToken.admin !== true) {
      return res.status(403).json({ error: 'Administrator access required' });
    }
    req.adminUid = decodedToken.uid;
    return next();
  } catch {
    return res.status(401).json({ error: 'Invalid ID token' });
  }
}

app.get('/', (req, res) => {
  res.send('Firebase backend is running');
});

app.get('/admin/members', requireAdmin, async (req, res) => {
  const status = req.query.status ?? 'pending';
  const allowedStatuses = ['pending', 'approved', 'rejected', 'suspended'];
  if (!allowedStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid account status' });
  }

  try {
    const snapshot = await getFirestore()
      .collection('users')
      .where('status', '==', status)
      .limit(100)
      .get();
    return res.json(snapshot.docs.map((doc) => doc.data()));
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.patch('/admin/members/:uid/status', requireAdmin, async (req, res) => {
  const { status, reason } = req.body;
  const allowedStatuses = ['approved', 'rejected', 'suspended'];
  if (!allowedStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid account status' });
  }

  try {
    const memberRef = getFirestore().collection('users').doc(req.params.uid);
    const member = await memberRef.get();
    if (!member.exists) return res.status(404).json({ error: 'User not found' });

    await memberRef.update({
      status,
      ...(status === 'approved'
        ? { approvedAt: FieldValue.serverTimestamp(), approvedBy: req.adminUid }
        : {}),
      ...(reason ? { statusReason: reason } : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });
    await writeAuditLog({
      action: `member_${status}`,
      actorUid: req.adminUid,
      targetUid: req.params.uid,
      details: { status, ...(reason ? { reason } : {}) },
    });
    return res.json({ uid: req.params.uid, status });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.post('/admin/members/:uid/promote', requireAdmin, async (req, res) => {
  try {
    const authUser = await getAuth().getUser(req.params.uid);
    const memberRef = getFirestore().collection('users').doc(req.params.uid);
    const member = await memberRef.get();
    if (!member.exists || member.data().status !== 'approved') {
      return res.status(400).json({ error: 'Only approved members can be promoted' });
    }

    await getAuth().setCustomUserClaims(req.params.uid, {
      ...(authUser.customClaims ?? {}),
      admin: true,
    });
    await memberRef.update({
      role: 'admin',
      updatedAt: FieldValue.serverTimestamp(),
    });
    await writeAuditLog({
      action: 'member_promoted_to_admin',
      actorUid: req.adminUid,
      targetUid: req.params.uid,
      details: { role: 'admin' },
    });
    return res.json({ uid: req.params.uid, role: 'admin' });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${PORT}`);
});
