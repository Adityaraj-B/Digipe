const mongoose = require('mongoose');
const { POLICY_STATUS } = require('../constants');

const policySchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
      index: true,
    },
    order: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
      required: [true, 'Order is required'],
      index: true,
    },
    orderItem: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'OrderItem',
      required: [true, 'Order item is required'],
    },
    plan: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'InsurancePlan',
      required: [true, 'Plan is required'],
      index: true,
    },
    application: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'InsuranceApplication',
      required: [true, 'Application is required'],
    },
    policyNumber: {
      type: String,
      unique: true,
      index: true,
    },
    startDate: {
      type: Date,
      required: [true, 'Start date is required'],
    },
    endDate: {
      type: Date,
      required: [true, 'End date is required'],
    },
    coverageAmount: {
      type: Number,
      required: [true, 'Coverage amount is required'],
      min: 0,
    },
    premium: {
      type: Number,
      required: [true, 'Premium is required'],
      min: 0,
    },
    status: {
      type: String,
      enum: Object.values(POLICY_STATUS),
      default: POLICY_STATUS.ACTIVE,
      index: true,
    },
    isDeleted: {
      type: Boolean,
      default: false,
      index: true,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

policySchema.index({ user: 1, isDeleted: 1 });
policySchema.index({ user: 1, status: 1, isDeleted: 1 });
policySchema.index({ policyNumber: 1, isDeleted: 1 });

policySchema.pre(/^find/, function (next) {
  if (this.getQuery().includeDeleted !== true) {
    this.where({ isDeleted: false });
  }
  next();
});

policySchema.virtual('claims', {
  ref: 'Claim',
  localField: '_id',
  foreignField: 'policy',
});

module.exports = mongoose.model('Policy', policySchema);
