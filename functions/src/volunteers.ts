import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { isAtLeastRole } from './helpers';

const db = admin.firestore();
const auth = admin.auth();

export const applyAsVolunteer =
  functions.https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication required',
        );
      }

      const {
        opportunityId,
        motivation,
        availability,
        skills,
      } = data as {
        opportunityId: string;
        motivation: string;
        availability: string;
        skills?: string[];
      };

      // TASK 27: Validate application input.
      if (
        !opportunityId ||
        typeof motivation !== 'string' ||
        motivation.trim().length < 10 ||
        typeof availability !== 'string' ||
        availability.trim().length < 3
      ) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Valid opportunity, motivation and availability are required',
        );
      }

      // TASK 27: Get user data from Firestore.
      const userDoc =
        await db
          .collection('users')
          .doc(context.auth.uid)
          .get();

      const userData = userDoc.data();

      // TASK 27: Only approved members can apply.
      if (
        !userData ||
        userData.status !== 'approved'
      ) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Only approved members can apply',
        );
      }

      const opportunityRef =
        db.collection('opportunities').doc(opportunityId);

      const opportunityDoc =
        await opportunityRef.get();

      if (!opportunityDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Opportunity not found',
        );
      }

      const opportunity =
        opportunityDoc.data()!;

      // TASK 27: Opportunity must be active.
      if (opportunity.status !== 'active') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Opportunity is not active',
        );
      }

      // TASK 27: Check application deadline.
      if (opportunity.deadline) {
        const deadline =
          opportunity.deadline.toDate();

        if (new Date() > deadline) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Application deadline has passed',
          );
        }
      }

      // TASK 27: Prevent duplicate applications.
      const duplicate =
        await db
          .collection('volunteers')
          .where(
            'userId',
            '==',
            context.auth.uid,
          )
          .where(
            'opportunityId',
            '==',
            opportunityId,
          )
          .limit(1)
          .get();

      if (!duplicate.empty) {
        throw new functions.https.HttpsError(
          'already-exists',
          'You have already applied for this opportunity',
        );
      }

      // TASK 27: Capacity check.
      if (
        opportunity.maxParticipants !== undefined &&
        opportunity.maxParticipants !== null
      ) {
        const currentApplications =
          await db
            .collection('volunteers')
            .where(
              'opportunityId',
              '==',
              opportunityId,
            )
            .where(
              'status',
              'in',
              ['pending', 'accepted'],
            )
            .get();

        if (
          currentApplications.size >=
          opportunity.maxParticipants
        ) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Opportunity capacity has been reached',
          );
        }
      }

      const now =
        admin.firestore.Timestamp.now();

      const applicationRef =
        db.collection('volunteers').doc();

      const applicationData = {
        id: applicationRef.id,
        userId: context.auth.uid,
        opportunityId,
        motivation: motivation.trim(),
        availability: availability.trim(),
        skills: Array.isArray(skills)
          ? skills.slice(0, 30)
          : [],
        status: 'pending',
        appliedAt: now,
        reviewedAt: null,
        reviewedBy: null,
        createdAt: now,
        updatedAt: now,
      };

      await applicationRef.set(applicationData);

      await db.collection('audit_logs').add({
        actionType: 'CREATE',
        userId: context.auth.uid,
        userRole: userData.role || 'member',
        targetCollection: 'volunteers',
        targetDocumentId: applicationRef.id,
        beforeValue: null,
        afterValue: {
          opportunityId,
          status: 'pending',
        },
        timestamp: now,
      });

      return {
        applicationId: applicationRef.id,
        ...applicationData,
      };
    } catch (error) {
      functions.logger.error(
        'applyAsVolunteer error',
        error,
      );

      if (
        error instanceof functions.https.HttpsError
      ) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to submit volunteer application',
      );
    }
  });

export const updateVolunteerStatus =
  functions.https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication required',
        );
      }

      const callerToken =
        await auth.getUser(context.auth.uid);

      const claims =
        callerToken.customClaims || {};

      if (
        !isAtLeastRole(
          'opportunity_manager',
          claims,
        )
      ) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only opportunity managers and above can update volunteer status',
        );
      }

      const {
        applicationId,
        status,
        reviewNotes,
      } = data as {
        applicationId: string;
        status:
          | 'accepted'
          | 'rejected'
          | 'completed';
        reviewNotes?: string;
      };

      if (!applicationId || !status) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'applicationId and status are required',
        );
      }

      // Validate status explicitly.
      const allowedStatuses = [
        'accepted',
        'rejected',
        'completed',
      ];

      if (!allowedStatuses.includes(status)) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid volunteer application status',
        );
      }

      const applicationDoc =
        await db
          .collection('volunteers')
          .doc(applicationId)
          .get();

      if (!applicationDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Application not found',
        );
      }

      const existingApplication =
        applicationDoc.data();

      const now =
        admin.firestore.Timestamp.now();

      const updateData: Record<string, unknown> = {
        status,
        reviewedAt: now,
        reviewedBy: context.auth.uid,
        updatedAt: now,
      };

      if (reviewNotes !== undefined) {
        updateData.reviewNotes = reviewNotes;
      }

      await db
        .collection('volunteers')
        .doc(applicationId)
        .update(updateData);

      await db.collection('audit_logs').add({
        actionType:
          status === 'accepted'
            ? 'APPROVE'
            : 'REJECT',
        userId: context.auth.uid,
        userRole: claims.role || 'unknown',
        targetCollection: 'volunteers',
        targetDocumentId: applicationId,
        beforeValue: existingApplication || null,
        afterValue: updateData,
        timestamp: now,
      });

      return {
        message: `Volunteer application ${status}`,
      };
    } catch (error) {
      functions.logger.error(
        'updateVolunteerStatus error',
        error,
      );

      if (
        error instanceof functions.https.HttpsError
      ) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to update volunteer status',
      );
    }
  });

export const withdrawVolunteerApplication =
  functions.https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication required',
        );
      }

      const { applicationId } =
        data as {
          applicationId: string;
        };

      if (!applicationId) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'applicationId is required',
        );
      }

      const applicationDoc =
        await db
          .collection('volunteers')
          .doc(applicationId)
          .get();

      if (!applicationDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Application not found',
        );
      }

      const applicationData =
        applicationDoc.data();

      if (
        applicationData?.userId !==
        context.auth.uid
      ) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'You can only withdraw your own applications',
        );
      }

      // TASK 28:
      // Do NOT physically delete the application.
      const now =
        admin.firestore.Timestamp.now();

      const updateData = {
        status: 'withdrawn',
        withdrawnAt: now,
        updatedAt: now,
      };

      await db
        .collection('volunteers')
        .doc(applicationId)
        .update(updateData);

      // TASK 28: Audit as WITHDRAW instead of DELETE.
      await db.collection('audit_logs').add({
        actionType: 'WITHDRAW',
        userId: context.auth.uid,
        userRole: 'member',
        targetCollection: 'volunteers',
        targetDocumentId: applicationId,
        beforeValue: applicationData,
        afterValue: updateData,
        timestamp: now,
      });

      return {
        message:
          'Application withdrawn successfully',
      };
    } catch (error) {
      functions.logger.error(
        'withdrawVolunteerApplication error',
        error,
      );

      if (
        error instanceof functions.https.HttpsError
      ) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to withdraw application',
      );
    }
  });

export const getVolunteerDirectory =
  functions.https.onCall(async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Authentication required',
        );
      }

      const callerToken =
        await auth.getUser(context.auth.uid);

      const claims =
        callerToken.customClaims || {};

      if (
        !isAtLeastRole(
          'opportunity_manager',
          claims,
        )
      ) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only opportunity managers and above can view volunteer directory',
        );
      }

      const {
        status,
        opportunityId,
      } = data as {
        status?: string;
        opportunityId?: string;
      };

      let query: admin.firestore.Query =
        db.collection('volunteers');

      if (status) {
        query = query.where(
          'status',
          '==',
          status,
        );
      }

      if (opportunityId) {
        query = query.where(
          'opportunityId',
          '==',
          opportunityId,
        );
      }

      const snapshot =
        await query
          .orderBy('appliedAt', 'desc')
          .limit(100)
          .get();

      const volunteers =
        snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));

      return { volunteers };
    } catch (error) {
      functions.logger.error(
        'getVolunteerDirectory error',
        error,
      );

      if (
        error instanceof functions.https.HttpsError
      ) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to load volunteer directory',
      );
    }
  });