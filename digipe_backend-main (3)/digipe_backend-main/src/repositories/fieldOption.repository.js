const BaseRepository = require('./base.repository');
const FieldOption = require('../models/fieldOption.model');

class FieldOptionRepository extends BaseRepository {
  constructor() {
    super(FieldOption);
  }

  async findByField(productFieldId) {
    return this.model.find({ productField: productFieldId, isActive: true }).sort({ sortOrder: 1 });
  }

  async deleteByField(productFieldId) {
    return this.model.deleteMany({ productField: productFieldId });
  }
}

module.exports = new FieldOptionRepository();
