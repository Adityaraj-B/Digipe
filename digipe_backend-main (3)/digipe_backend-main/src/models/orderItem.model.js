const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema(
  {
    order: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
      required: [true, 'Order is required'],
    },
    plan: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'InsurancePlan',
      required: [true, 'Plan is required'],
    },
    application: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'InsuranceApplication',
      required: [true, 'Application is required'],
    },
    premium: {
      type: Number,
      required: [true, 'Premium is required'],
      min: 0,
    },
    coverageAmount: {
      type: Number,
      required: [true, 'Coverage amount is required'],
      min: 0,
    },
  },
  {
    timestamps: true,
  }
);

orderItemSchema.index({ order: 1 });

module.exports = mongoose.model('OrderItem', orderItemSchema);
