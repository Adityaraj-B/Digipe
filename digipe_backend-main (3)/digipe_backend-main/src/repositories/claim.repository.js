const BaseRepository = require('./base.repository');
const Claim = require('../models/claim.model');

class ClaimRepository extends BaseRepository {
  constructor() {
    super(Claim);
  }

  async findByUser(userId, options = {}) {
    return this.findWithPagination({ user: userId }, {
      ...options,
      populate: [
        { path: 'policy', select: 'policyNumber coverageAmount status', populate: { path: 'plan', select: 'name' } },
      ],
    });
  }

  async findByIdWithDetails(id) {
    return this.model.findById(id)
      .populate('user', 'name mobileNumber email')
      .populate({
        path: 'policy',
        select: 'policyNumber coverageAmount premium startDate endDate status',
        populate: { path: 'plan', select: 'name coverageAmount premium', populate: { path: 'product', select: 'name slug' } },
      })
      .populate('reviewedBy', 'name mobileNumber')
      .populate({
        path: 'documents',
        match: { isDeleted: false },
        populate: { path: 'document', select: 'originalName url mimeType size' },
      });
  }

  async findByPolicy(policyId) {
    return this.model.find({ policy: policyId, isDeleted: false });
  }

  async findActiveByPolicy(policyId) {
    return this.model.findOne({
      policy: policyId,
      status: { $in: ['SUBMITTED', 'UNDER_REVIEW', 'APPROVED'] },
      isDeleted: false,
    });
  }
}

module.exports = new ClaimRepository();
