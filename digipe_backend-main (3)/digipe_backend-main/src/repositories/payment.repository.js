const BaseRepository = require('./base.repository');
const Payment = require('../models/payment.model');

class PaymentRepository extends BaseRepository {
  constructor() {
    super(Payment);
  }

  async findByOrder(orderId) {
    return this.model.findOne({ order: orderId }).populate('order');
  }

  async findByTransactionId(transactionId) {
    return this.model.findOne({ transactionId });
  }

  async findByCashfreeOrderId(cashfreeOrderId) {
    return this.model.findOne({ cashfreeOrderId }).populate('order');
  }

  async findByUser(userId, options = {}) {
    return this.findWithPagination({ user: userId }, options);
  }
}

module.exports = new PaymentRepository();
