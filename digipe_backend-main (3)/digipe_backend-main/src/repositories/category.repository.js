const BaseRepository = require('./base.repository');
const InsuranceCategory = require('../models/insuranceCategory.model');

class CategoryRepository extends BaseRepository {
  constructor() {
    super(InsuranceCategory);
  }

  async findBySlug(slug) {
    return this.model.findOne({ slug });
  }

  async findByName(name) {
    return this.model.findOne({ name: { $regex: new RegExp(`^${name}$`, 'i') } });
  }

  async findActiveCategories(options = {}) {
    return this.findAll({ isActive: true }, options);
  }
}

module.exports = new CategoryRepository();
