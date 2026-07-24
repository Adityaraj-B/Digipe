const BaseRepository = require('./base.repository');
const Policy = require('../models/policy.model');

class PolicyRepository extends BaseRepository {
  constructor() {
    super(Policy);
  }

  async findByUser(userId, options = {}) {
    return this.findWithPagination({ user: userId }, {
      ...options,
      populate: [
        { path: 'plan', select: 'name coverageAmount premium premiumFrequency duration', populate: { path: 'product', select: 'name slug image' } },
        { path: 'application', select: 'applicationNumber' },
      ],
    });
  }

  async findByIdWithDetails(id) {
    return this.model.findById(id)
      .populate('user', 'name mobileNumber email')
      .populate('order', 'orderNumber totalAmount status')
      .populate({
        path: 'plan',
        select: 'name coverageAmount premium premiumFrequency duration features benefits exclusions',
        populate: { path: 'product', select: 'name slug image category' },
      })
      .populate('application', 'applicationNumber status')
      .populate({ path: 'claims', match: { isDeleted: false } });
  }

  async findByPolicyNumber(policyNumber) {
    return this.model.findOne({ policyNumber });
  }

  async findActiveByUser(userId) {
    return this.model.find({ user: userId, status: 'ACTIVE' })
      .populate('plan', 'name coverageAmount premium');
  }
}

module.exports = new PolicyRepository();
