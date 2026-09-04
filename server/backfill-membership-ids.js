const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize with explicit project ID
initializeApp({
  credential: applicationDefault(),
  projectId: 'pynp-mobile-management-system',
});

const db = getFirestore();

async function backfillMembershipIds() {
  try {
    console.log('Starting membership ID backfill...');
    
    // Get all users
    const usersSnapshot = await db
      .collection('users')
      .get();

    console.log(`Found ${usersSnapshot.size} total users`);

    let updatedCount = 0;
    let skippedCount = 0;
    let batch = db.batch();
    let batchCount = 0;

    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      
      // Skip if user already has a membershipId
      if (userData.membershipId) {
        console.log(`Skipping user ${doc.id} - already has membership ID: ${userData.membershipId}`);
        skippedCount++;
        continue;
      }

      // Generate membership ID
      const year = new Date().getFullYear();
      const sequence = String(updatedCount + 1).padStart(4, '0');
      const membershipId = `PYNP-${year}-${sequence}`;

      // Add to batch
      batch.update(doc.ref, {
        membershipId: membershipId,
        updatedAt: new Date(),
      });

      console.log(`Assigning ${membershipId} to user ${doc.id} (${userData.email || 'no email'})`);
      
      updatedCount++;
      batchCount++;

      // Firestore batch limit is 500 operations
      if (batchCount >= 450) {
        await batch.commit();
        console.log(`Committed batch of ${batchCount} updates`);
        batch = db.batch();
        batchCount = 0;
      }
    }

    // Commit any remaining updates
    if (batchCount > 0) {
      await batch.commit();
      console.log(`Committed final batch of ${batchCount} updates`);
    }

    console.log(`\nBackfill complete!`);
    console.log(`Updated: ${updatedCount} users`);
    console.log(`Skipped: ${skippedCount} users (already had membership ID)`);
    console.log(`Total: ${usersSnapshot.size} users`);

  } catch (error) {
    console.error('Error during backfill:', error);
    process.exit(1);
  }
}

// Run the backfill
backfillMembershipIds();