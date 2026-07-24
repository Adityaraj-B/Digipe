const mongoose = require('mongoose');
const env = require('./config/env');
const logger = require('./config/logger');
const User = require('./models/user.model');
const { ROLES } = require('./constants');

const ADMIN_MOBILE = '+918604707494';

const seedAdmin = async () => {
  try {
    const existingAdmin = await User.findOne({ mobileNumber: ADMIN_MOBILE });

    if (existingAdmin) {
      logger.info(`Admin already exists: ${existingAdmin.mobileNumber} (${existingAdmin._id})`);
      return existingAdmin;
    }

    const admin = await User.create({
      name: 'Super Admin',
      mobileNumber: ADMIN_MOBILE,
      email: 'admin@digipe.com',
      role: ROLES.ADMIN,
      isActive: true,
    });

    logger.info(`=================================================`);
    logger.info(`ADMIN USER SEEDED SUCCESSFULLY`);
    logger.info(`Name         : ${admin.name}`);
    logger.info(`Mobile       : ${admin.mobileNumber}`);
    logger.info(`Email        : ${admin.email}`);
    logger.info(`Role         : ${admin.role}`);
    logger.info(`ID           : ${admin._id}`);
    logger.info(`=================================================`);

    return admin;
  } catch (error) {
    logger.error(`Failed to seed admin: ${error.message}`);
  }
};

const runSeeder = async () => {
  try {
    await mongoose.connect(env.mongodbUri);
    logger.info(`MongoDB Connected for seeding`);

    await seedAdmin();

    await mongoose.connection.close();
    logger.info('Seeding complete. Connection closed.');
    process.exit(0);
  } catch (error) {
    logger.error(`Seeder error: ${error.message}`);
    process.exit(1);
  }
};

// Run directly: node src/seed.js
// Or import seedAdmin() to run at server startup
if (require.main === module) {
  runSeeder();
}

module.exports = { seedAdmin };
