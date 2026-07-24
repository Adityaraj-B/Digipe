const BaseRepository = require('./base.repository');
const InsuranceProduct = require('../models/insuranceProduct.model');

class ProductRepository extends BaseRepository {
  constructor() {
    super(InsuranceProduct);
  }

  async findBySlug(slug) {
    return this.model.findOne({ slug }).populate('category');
  }

  async findByCategory(categoryId, options = {}) {
    return this.findAll({ category: categoryId, isActive: true }, options);
  }

  async findByName(name) {
    return this.model.findOne({ name: { $regex: new RegExp(`^${name}$`, 'i') } });
  }

  async findByIdWithDetails(id) {
    return this.model.findById(id)
      .populate('category')
      .populate({ path: 'plans', match: { isDeleted: false, isActive: true } })
      .populate({ path: 'fields', match: { isDeleted: false, isActive: true }, populate: { path: 'options', match: { isActive: true } } });
  }
}

module.exports = new ProductRepository();
