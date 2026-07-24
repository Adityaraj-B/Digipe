const BaseRepository = require('./base.repository');
const OrderItem = require('../models/orderItem.model');

class OrderItemRepository extends BaseRepository {
  constructor() {
    super(OrderItem);
  }

  async findByOrder(orderId) {
    return this.model.find({ order: orderId })
      .populate({
        path: 'plan',
        select: 'name coverageAmount premium premiumFrequency duration',
        populate: { path: 'product', select: 'name slug' },
      })
      .populate('application', 'applicationNumber status');
  }

  async deleteByOrder(orderId) {
    return this.model.deleteMany({ order: orderId });
  }
}

module.exports = new OrderItemRepository();
