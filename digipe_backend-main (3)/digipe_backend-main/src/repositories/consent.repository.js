const BaseRepository = require('./base.repository');
const Consent = require('../models/consent.model');

class ConsentRepository extends BaseRepository {
  constructor() {
    super(Consent);
  }

  async findByApplication(applicationId) {
    return this.model.findOne({ application: applicationId })
      .populate('user', 'name mobileNumber email')
      .populate('adminUser', 'name mobileNumber');
  }

  async findByUserAndApplication(userId, applicationId) {
    return this.model.findOne({ user: userId, application: applicationId });
  }
}

module.exports = new ConsentRepository();
