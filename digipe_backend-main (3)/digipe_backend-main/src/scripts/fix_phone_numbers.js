/**
 * One-time migration script to fix phone number formats in the users collection.
 * 
 * What it does:
 * 1. Finds all users whose mobileNumber does NOT start with "+91"
 * 2. Normalizes them to +91XXXXXXXXXX format
 * 3. If a normalized duplicate already exists, merges them (keeps the one with more data)
 * 
 * Usage: node src/scripts/fix_phone_numbers.js
 */

const mongoose = require('mongoose');
const env = require('../config/env');
const logger = require('../config/logger');

// Use raw model to bypass pre-save hooks and soft-delete filters
const UserSchema = new mongoose.Schema({}, { strict: false, collection: 'users' });
const RawUser = mongoose.model('RawUser', UserSchema);

/**
 * Normalize phone to +91XXXXXXXXXX
 */
function normalizePhone(phone) {
  if (!phone) return phone;
  let digits = phone.replace(/\D/g, '');
  if (digits.length > 10 && digits.startsWith('91')) {
    digits = digits.slice(2);
  }
  return `+91${digits}`;
}

async function main() {
  await mongoose.connect(env.mongodbUri);
  logger.info('Connected to MongoDB for phone number migration');

  // Find all users with mobileNumber that doesn't start with +91
  const usersToFix = await RawUser.find({
    mobileNumber: { $exists: true, $ne: null, $not: /^\+91/ },
  }).lean();

  logger.info(`Found ${usersToFix.length} user(s) with non-normalized phone numbers`);

  if (usersToFix.length === 0) {
    logger.info('No users to fix. All phone numbers are already normalized.');
    await mongoose.connection.close();
    return;
  }

  let fixed = 0;
  let merged = 0;
  let skipped = 0;

  for (const user of usersToFix) {
    const normalized = normalizePhone(user.mobileNumber);
    
    console.log(`\n--- Processing: "${user.mobileNumber}" → "${normalized}" (ID: ${user._id}, role: ${user.role}) ---`);

    // Check if a user with the normalized number already exists
    const existingUser = await RawUser.findOne({
      mobileNumber: normalized,
      _id: { $ne: user._id },
    }).lean();

    if (existingUser) {
      // MERGE: Both records exist for the same phone number
      console.log(`  ⚠️  Duplicate found: ${existingUser._id} (role: ${existingUser.role})`);
      console.log(`  Merging into the record with role: ADMIN`);

      // Determine which one to keep (prefer ADMIN role per user instruction)
      let keepUser, deleteUser;
      if (user.role === 'ADMIN') {
        keepUser = user;
        deleteUser = existingUser;
      } else if (existingUser.role === 'ADMIN') {
        keepUser = existingUser;
        deleteUser = user;
      } else {
        // Neither is admin — keep the older one
        keepUser = user.createdAt <= existingUser.createdAt ? user : existingUser;
        deleteUser = user.createdAt <= existingUser.createdAt ? existingUser : user;
      }

      // Merge useful fields from deleteUser into keepUser
      const mergeFields = {};
      if (!keepUser.name && deleteUser.name) mergeFields.name = deleteUser.name;
      if (!keepUser.email && deleteUser.email) mergeFields.email = deleteUser.email;
      if (!keepUser.profileImage && deleteUser.profileImage) mergeFields.profileImage = deleteUser.profileImage;
      // Ensure the kept user has the normalized phone number
      mergeFields.mobileNumber = normalized;

      console.log(`  Keep: ${keepUser._id} (role: ${keepUser.role})`);
      console.log(`  Delete: ${deleteUser._id} (role: ${deleteUser.role})`);
      console.log(`  Merge fields:`, mergeFields);

      // Update the keeper
      await RawUser.updateOne({ _id: keepUser._id }, { $set: mergeFields });

      // Soft-delete the duplicate (mark as deleted, don't hard-delete for safety)
      await RawUser.updateOne({ _id: deleteUser._id }, {
        $set: {
          isDeleted: true,
          deletedAt: new Date(),
          mobileNumber: `MERGED_INTO_${keepUser._id}_${deleteUser.mobileNumber}`,
        },
      });

      console.log(`  ✅ Merged successfully`);
      merged++;
    } else {
      // No duplicate — just update the phone number
      await RawUser.updateOne(
        { _id: user._id },
        { $set: { mobileNumber: normalized } }
      );
      console.log(`  ✅ Updated to "${normalized}"`);
      fixed++;
    }
  }

  console.log('\n' + '='.repeat(50));
  console.log(`MIGRATION COMPLETE`);
  console.log(`  Fixed: ${fixed}`);
  console.log(`  Merged: ${merged}`);
  console.log(`  Skipped: ${skipped}`);
  console.log('='.repeat(50));

  // Verify: check for any remaining non-normalized numbers
  const remaining = await RawUser.countDocuments({
    mobileNumber: { $exists: true, $ne: null, $not: /^\+91/ },
    isDeleted: { $ne: true },
  });
  console.log(`\nRemaining non-normalized active users: ${remaining}`);
  
  if (remaining === 0) {
    console.log('✅ All phone numbers are now normalized!');
  } else {
    console.log('❌ Some numbers still need fixing — check manually.');
  }

  await mongoose.connection.close();
  logger.info('Migration connection closed.');
}

main().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
