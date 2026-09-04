import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

import {
  logActivity,
  toFirestoreTimestamp,
  validateCnicFormat,
  normalizeCnic,
  hmacSha256,
} from './helpers';

const db = admin.firestore();

const CNIC_ENCRYPTION_KEY = process.env.CNIC_ENCRYPTION_KEY;
const CNIC_HMAC_SECRET = process.env.CNIC_HMAC_SECRET;

function getEncryptionKey(): Buffer {
  if (!CNIC_ENCRYPTION_KEY) {
    throw new Error('CNIC_ENCRYPTION_KEY is not configured');
  }

  const key = Buffer.from(CNIC_ENCRYPTION_KEY, 'hex');

  if (key.length !== 32) {
    throw new Error('CNIC_ENCRYPTION_KEY must be exactly 32 bytes');
  }

  return key;
}

function getHmacSecret(): string {
  if (!CNIC_HMAC_SECRET) {
    throw new Error('CNIC_HMAC_SECRET is not configured');
  }

  return CNIC_HMAC_SECRET;
}

function encryptCnic(cnic: string): {
  ciphertext: string;
  iv: string;
  authTag: string;
} {
  const key = getEncryptionKey();

  const iv = crypto.randomBytes(12);

  const cipher = crypto.createCipheriv(
    'aes-256-gcm',
    key,
    iv,
  );

  const ciphertext = Buffer.concat([
    cipher.update(cnic, 'utf8'),
    cipher.final(),
  ]);

  const authTag = cipher.getAuthTag();

  return {
    ciphertext: ciphertext.toString('base64'),
    iv: iv.toString('base64'),
    authTag: authTag.toString('base64'),
  };
}

export const submitRegistration =
  functions.https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication required',
        );
      }

      const uid = context.auth.uid;

      const {
        fullName,
        fatherName,
        cnic,
        dateOfBirth,
        gender,
        province,
        district,
        city,
        phone,
        email,
        education,
        employment,
        skills,
        emergencyContactName,
        emergencyContactPhone,
        referralSource,
        organizationId,
        cnicFrontUrl,
        cnicBackUrl,
        cvUrl,
        paymentProofUrl,
        membershipType,
      } = data as Record<string, unknown>;

      if (
        typeof fullName !== 'string' ||
        fullName.trim().length < 2 ||
        fullName.trim().length > 100
      ) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Full name must contain 2-100 characters',
        );
      }

      if (typeof cnic !== 'string') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'CNIC is required',
        );
      }

      const normalizedCnic = normalizeCnic(cnic);

      if (!validateCnicFormat(normalizedCnic)) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'CNIC must contain exactly 13 digits',
        );
      }

      const dateOfBirthTimestamp =
        dateOfBirth != null
          ? toFirestoreTimestamp(dateOfBirth)
          : undefined;

      if (dateOfBirth != null && !dateOfBirthTimestamp) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid date of birth',
        );
      }

      const now = admin.firestore.Timestamp.now();

      const userRef = db.collection('users').doc(uid);

      const lookupId = hmacSha256(
        normalizedCnic,
        getHmacSecret(),
      );

      const lookupRef = db
        .collection('cnic_lookup')
        .doc(lookupId);

      const encrypted = encryptCnic(normalizedCnic);

      const userData: Record<string, unknown> = {
        uid,
        fullName: fullName.trim(),
        fatherName:
          typeof fatherName === 'string'
            ? fatherName.trim()
            : '',
        encryptedCnic: encrypted,
        dateOfBirth: dateOfBirthTimestamp ?? null,
        gender:
          typeof gender === 'string' ? gender.trim() : '',
        province:
          typeof province === 'string'
            ? province.trim()
            : '',
        district:
          typeof district === 'string'
            ? district.trim()
            : '',
        city:
          typeof city === 'string'
            ? city.trim()
            : '',
        phone:
          typeof phone === 'string' ? phone.trim() : '',
        email:
          typeof email === 'string' ? email.trim() : '',
        education:
          typeof education === 'string'
            ? education.trim()
            : '',
        employment:
          typeof employment === 'string'
            ? employment.trim()
            : '',
        skills:
          Array.isArray(skills) ? skills : [],
        emergencyContactName:
          typeof emergencyContactName === 'string'
            ? emergencyContactName.trim()
            : '',
        emergencyContactPhone:
          typeof emergencyContactPhone === 'string'
            ? emergencyContactPhone.trim()
            : '',
        referralSource:
          typeof referralSource === 'string'
            ? referralSource.trim()
            : '',
        organizationId:
          typeof organizationId === 'string'
            ? organizationId
            : 'unassigned',
        cnicFrontUrl:
          typeof cnicFrontUrl === 'string'
            ? cnicFrontUrl
            : '',
        cnicBackUrl:
          typeof cnicBackUrl === 'string'
            ? cnicBackUrl
            : '',
        cvUrl:
          typeof cvUrl === 'string' ? cvUrl : '',
        paymentProofUrl:
          typeof paymentProofUrl === 'string'
            ? paymentProofUrl
            : '',
        membershipType:
          typeof membershipType === 'string'
            ? membershipType
            : 'youth_mpa',
        role: 'member',
        status: 'pending',
        emailVerified: false,
        createdAt: now,
        updatedAt: now,
      };

      await db.runTransaction(async (transaction) => {
        const existingLookup =
          await transaction.get(lookupRef);

        if (existingLookup.exists) {
          throw new functions.https.HttpsError(
            'already-exists',
            'This CNIC is already registered',
          );
        }

        transaction.create(lookupRef, {
          userId: uid,
          createdAt: now,
        });

        transaction.set(
          userRef,
          userData,
          { merge: true },
        );
      });

      await db.collection('audit_logs').add({
        actionType: 'REGISTRATION_SUBMITTED',
        userId: uid,
        userRole: 'member',
        targetCollection: 'users',
        targetDocumentId: uid,
        beforeValue: null,
        afterValue: {
          fullName: userData.fullName,
          email: userData.email,
          province: userData.province,
          district: userData.district,
          city: userData.city,
          membershipType: userData.membershipType,
        },
        timestamp: now,
      });

      await logActivity(db, {
        title: 'New registration',
        type: 'member',
        subtitle:
          typeof email === 'string'
            ? email
            : fullName.trim(),
        userId: uid,
      });

      return {
        success: true,
        message: 'Registration submitted successfully',
        uid,
      };
    } catch (error) {
      functions.logger.error(
        'submitRegistration error',
        error,
      );

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to submit registration',
      );
    }
  });