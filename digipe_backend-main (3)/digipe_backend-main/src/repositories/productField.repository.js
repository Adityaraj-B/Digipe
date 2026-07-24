const BaseRepository = require('./base.repository');
const ProductField = require('../models/productField.model');

class ProductFieldRepository extends BaseRepository {
  constructor() {
    super(ProductField);
  }

  async findByProduct(productId) {
    return this.model
      .find({ product: productId, isActive: true })
      .populate({ path: 'options', match: { isActive: true }, options: { sort: { sortOrder: 1 } } })
      .sort({ sortOrder: 1 });
  }

  async findByProductRaw(productId) {
    return this.model.find({ product: productId });
  }
}

module.exports = new ProductFieldRepository();
