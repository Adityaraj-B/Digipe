const mongoose = require('mongoose');

/**
 * Schema to track Hubble SDK transactions (gift card purchases, voucher generation, etc.)
 * These records come from Hubble webhooks and SDK analytics events.
 */
const hubbleTransactionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    hubbleTransactionId: {
      type: String,
      index: true,
      sparse: true,
    },
    eventType: {
      type: String,
      enum: [
        'payment_initiated',
        'payment_success',
        'payment_failed',
        'voucher_generated',
        'voucher_redeemed',
        'order_placed',
        'refund_initiated',
        'refund_completed',
        'other',
      ],
      required: true,
      index: true,
    },
    brand: {
      type: String,
      trim: true,
      default: null,
    },
    amount: {
      type: Number,
      default: 0,
    },
    currency: {
      type: String,
      default: 'INR',
    },
    voucherCode: {
      type: String,
      default: null,
    },
    status: {
      type: String,
      enum: ['pending', 'completed', 'failed', 'refunded'],
      default: 'pending',
    },
    rawPayload: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

hubbleTransactionSchema.index({ userId: 1, createdAt: -1 });
hubbleTransactionSchema.index({ eventType: 1, createdAt: -1 });

module.exports = mongoose.model('HubbleTransaction', hubbleTransactionSchema);
