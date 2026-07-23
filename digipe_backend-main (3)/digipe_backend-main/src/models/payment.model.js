const mongoose = require('mongoose');
const { PAYMENT_METHOD, PAYMENT_TRANSACTION_STATUS } = require('../constants');

const paymentSchema = new mongoose.Schema(
  {
    order: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
      required: [true, 'Order is required'],
      index: true,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
      index: true,
    },
    amount: {
      type: Number,
      required: [true, 'Amount is required'],
      min: 0,
    },
    paymentMethod: {
      type: String,
      enum: [...Object.values(PAYMENT_METHOD), null],
      default: null,
    },
    transactionId: {
      type: String,
      unique: true,
      sparse: true,
      index: true,
    },
    cashfreeOrderId: {
      type: String,
      index: true,
      default: null,
    },
    paymentSessionId: {
      type: String,
      default: null,
    },
    // Store the raw response from the Cashfree payment gateway
    // for reconciliation, debugging, and audit trail purposes.
    gatewayResponse: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    status: {
      type: String,
      enum: Object.values(PAYMENT_TRANSACTION_STATUS),
      default: PAYMENT_TRANSACTION_STATUS.PENDING,
      index: true,
    },
    paidAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

paymentSchema.index({ order: 1, status: 1 });
paymentSchema.index({ user: 1, status: 1 });

module.exports = mongoose.model('Payment', paymentSchema);
