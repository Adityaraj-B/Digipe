const BaseRepository = require('./base.repository');
const ClaimDocument = require('../models/claimDocument.model');

class ClaimDocumentRepository extends BaseRepository {
  constructor() {
    super(ClaimDocument);
  }

  async findByClaim(claimId) {
    return this.model.find({ claim: claimId, isDeleted: false })
      .populate('document', 'originalName url mimeType size');
  }

  async deleteByClaim(claimId) {
    return this.model.updateMany(
      { claim: claimId },
      { $set: { isDeleted: true } }
    );
  }
}

module.exports = new ClaimDocumentRepository();
