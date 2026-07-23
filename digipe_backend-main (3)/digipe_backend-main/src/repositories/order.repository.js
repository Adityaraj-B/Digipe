const BaseRepository = require('./base.repository');
const Order = require('../models/order.model');

class OrderRepository extends BaseRepository {
  constructor() {
    super(Order);
  }

  async findByUser(userId, options = {}) {
    return this.findWithPagination({ user: userId }, {
      ...options,
      populate: { path: 'items', populate: { path: 'plan', select: 'name coverageAmount premium' } },
    });
  }

  async findByIdWithDetails(id) {
    return this.model.findById(id)
      .populate('user', 'name mobileNumber email')
      .populate({
        path: 'items',
        populate: [
          { path: 'plan', select: 'name coverageAmount premium premiumFrequency duration', populate: { path: 'product', select: 'name slug' } },
          { path: 'application', select: 'applicationNumber status' },
        ],
      })
      .populate('payment');
  }

  async findByOrderNumber(orderNumber) {
    return this.model.findOne({ orderNumber });
  }
}

module.exports = new OrderRepository();
