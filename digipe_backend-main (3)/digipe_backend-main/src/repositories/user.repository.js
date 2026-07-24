const BaseRepository = require('./base.repository');
const User = require('../models/user.model');
const { normalizePhone } = require('../utils/helpers');

class UserRepository extends BaseRepository {
  constructor() {
    super(User);
  }

  async findByMobileNumber(mobileNumber) {
    return this.model.findOne({ mobileNumber: normalizePhone(mobileNumber) });
  }

  async findByEmail(email) {
    return this.model.findOne({ email });
  }

  async findActiveById(id) {
    return this.model.findOne({ _id: id, isActive: true });
  }
}

module.exports = new UserRepository();
