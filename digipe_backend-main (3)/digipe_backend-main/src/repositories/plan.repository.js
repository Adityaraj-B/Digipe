const BaseRepository = require('./base.repository');
const InsurancePlan = require('../models/insurancePlan.model');

class PlanRepository extends BaseRepository {
  constructor() {
    super(InsurancePlan);
  }

  async findByProduct(productId, options = {}) {
    return this.findAll({ product: productId, isActive: true }, options);
  }

  async countByProduct(productId) {
    return this.count({ product: productId });
  }

  async findByIdWithProduct(id) {
    return this.model.findById(id).populate('product');
  }
}

module.exports = new PlanRepository();
