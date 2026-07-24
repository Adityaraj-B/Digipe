/**
 * Cleanup Script — Delete ALL orders and related data.
 *
 * This removes:
 *   - Orders
 *   - Order Items
 *   - Payments
 *   - Policies
 *   - Claims
 *   - Claim Documents
 *   - Applications
 *   - Application Field Values
 *   - Consents
 *   - Audit Logs
 *
 * Usage:  node src/scripts/cleanup-all-orders.js
 */

const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/digipe_insurance';

async function cleanup() {
  console.log('\n🔌 Connecting to MongoDB...');
  console.log(`   URI: ${MONGODB_URI}\n`);

  await mongoose.connect(MONGODB_URI);
  const db = mongoose.connection.db;

  // Collections to wipe (in dependency order)
  const collections = [
    'claims',
    'claimdocuments',
    'policies',
    'payments',
    'orderitems',
    'orders',
    'consents',
    'applicationfieldvalues',
    'insuranceapplications',
    'auditlogs',
  ];

  console.log('🗑️  Deleting all data from the following collections:\n');

  for (const name of collections) {
    try {
      const col = db.collection(name);
      const count = await col.countDocuments();
      if (count > 0) {
        const result = await col.deleteMany({});
        console.log(`   ✅ ${name}: deleted ${result.deletedCount} documents`);
      } else {
        console.log(`   ⏭️  ${name}: already empty`);
      }
    } catch (err) {
      // Collection might not exist yet — that's fine
      console.log(`   ⏭️  ${name}: collection does not exist`);
    }
  }

  console.log('\n✅ Cleanup complete! All orders, payments, policies, claims, and applications have been deleted.');
  console.log('   Categories, Products, Plans, Product Fields, and Users are untouched.\n');

  await mongoose.connection.close();
  process.exit(0);
}

cleanup().catch((err) => {
  console.error('\n❌ Cleanup failed:', err.message);
  process.exit(1);
});
