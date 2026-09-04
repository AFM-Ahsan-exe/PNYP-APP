import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

const db = admin.firestore();

let transporter: ReturnType<typeof nodemailer.createTransport> | null = null;

function getTransporter(): ReturnType<typeof nodemailer.createTransport> {
  // Use Secret Manager for credentials
  const GMAIL_USER = process.env.GMAIL_USER || functions.config().secrets?.gmail_user;
  const GMAIL_PASS = process.env.GMAIL_PASS || functions.config().secrets?.gmail_pass;

  if (!GMAIL_USER || !GMAIL_PASS) {
    throw new Error('GMAIL_USER and GMAIL_PASS secrets are required for email sending');
  }

  if (!transporter) {
    transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: GMAIL_USER,
        pass: GMAIL_PASS,
      },
    });
  }

  return transporter;
}

export const sendEmail = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }

    const callerToken = await admin.auth().getUser(context.auth.uid);
    const callerClaims = callerToken.customClaims || {};
    if (callerClaims.admin !== true && callerClaims.role !== 'national_admin' && callerClaims.role !== 'president' && callerClaims.role !== 'super_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only administrators can send emails');
    }

    const { to, subject, html, text } = data as {
      to: string;
      subject: string;
      html?: string;
      text?: string;
    };

    if (!to || !subject) {
      throw new functions.https.HttpsError('invalid-argument', 'to and subject are required');
    }

    const GMAIL_USER = process.env.GMAIL_USER || functions.config().secrets?.gmail_user;
    
    const info = await getTransporter().sendMail({
      from: `"PYNP" <${GMAIL_USER}>`,
      to,
      subject,
      text: text || html?.replace(/(<[^>]*>)/g, '') || '',
      html,
    });

    await db.collection('audit_logs').add({
      actionType: 'UPDATE',
      userId: context.auth.uid,
      userRole: callerClaims.role || 'admin',
      targetCollection: 'email',
      targetDocumentId: info.messageId,
      beforeValue: null,
      afterValue: { to, subject, messageId: info.messageId },
      timestamp: admin.firestore.Timestamp.now(),
    });

    return {
      messageId: info.messageId,
      message: 'Email sent successfully',
    };
  } catch (error) {
    functions.logger.error('sendEmail error', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to send email');
  }
});