const BaseRepository = require('./base.repository');
const Document = require('../models/document.model');

class DocumentRepository extends BaseRepository {
  constructor() {
    super(Document);
  }

  async findByUser(userId, options = {}) {
    return this.findWithPagination({ user: userId }, options);
  }

  async findByCloudinaryId(cloudinaryPublicId) {
    return this.model.findOne({ cloudinaryPublicId });
  }

  async findByApplication(applicationId) {
    return this.model.find({ application: applicationId, isDeleted: false })
      .sort({ createdAt: -1 });
  }
}

module.exports = new DocumentRepository();
