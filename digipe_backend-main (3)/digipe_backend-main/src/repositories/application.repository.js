const BaseRepository = require('./base.repository');
const InsuranceApplication = require('../models/insuranceApplication.model');

class ApplicationRepository extends BaseRepository {
  constructor() {
    super(InsuranceApplication);
  }

  async findByUser(userId, options = {}) {
    const filter = { user: userId };
    return this.findWithPagination(filter, {
      ...options,
      populate: [
        { path: 'product', select: 'name slug image' },
        { path: 'plan', select: 'name coverageAmount premium' },
      ],
    });
  }

  async findByIdWithDetails(id) {
    return this.model.findById(id)
      .populate('user', 'name mobileNumber email')
      .populate('product', 'name slug image')
      .populate('plan', 'name coverageAmount premium premiumFrequency duration')
      .populate('reviewedBy', 'name mobileNumber')
      .populate({
        path: 'fieldValues',
        match: { isDeleted: false },
        populate: { path: 'productField', select: 'fieldName fieldLabel fieldType' },
      });
  }

  async findByUserAndPlan(userId, planId) {
    return this.model.findOne({ user: userId, plan: planId, isDeleted: false });
  }
}

module.exports = new ApplicationRepository();
