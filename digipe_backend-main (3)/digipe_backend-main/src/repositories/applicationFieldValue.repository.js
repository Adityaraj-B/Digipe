const BaseRepository = require('./base.repository');
const ApplicationFieldValue = require('../models/applicationFieldValue.model');

class ApplicationFieldValueRepository extends BaseRepository {
  constructor() {
    super(ApplicationFieldValue);
  }

  async findByApplication(applicationId) {
    return this.model.find({ application: applicationId, isDeleted: false })
      .populate('productField', 'fieldName fieldLabel fieldType');
  }

  async deleteByApplication(applicationId) {
    return this.model.updateMany(
      { application: applicationId },
      { $set: { isDeleted: true } }
    );
  }
}

module.exports = new ApplicationFieldValueRepository();
