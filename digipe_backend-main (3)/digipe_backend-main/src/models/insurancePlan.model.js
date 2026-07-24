const mongoose = require('mongoose');
const { PREMIUM_FREQUENCY } = require('../constants');

const insurancePlanSchema = new mongoose.Schema(
  {
    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'InsuranceProduct',
      required: [true, 'Product is required'],
      index: true,
    },
    name: {
      type: String,
      required: [true, 'Plan name is required'],
      trim: true,
      maxlength: 200,
    },
    description: {
      type: String,
      trim: true,
      maxlength: 3000,
      default: null,
    },
    coverageAmount: {
      type: Number,
      required: [true, 'Coverage amount is required'],
      min: 0,
    },
    premium: {
      type: Number,
      required: [true, 'Premium amount is required'],
      min: 0,
    },
    premiumFrequency: {
      type: String,
      enum: Object.values(PREMIUM_FREQUENCY),
      default: PREMIUM_FREQUENCY.YEARLY,
    },
    duration: {
      type: Number,
      required: [true, 'Duration is required'],
      min: 1,
      comment: 'Duration in months',
    },
    features: [
      {
        type: String,
        trim: true,
      },
    ],
    benefits: [
      {
        type: String,
        trim: true,
      },
    ],
    exclusions: [
      {
        type: String,
        trim: true,
      },
    ],
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    sortOrder: {
      type: Number,
      default: 0,
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

insurancePlanSchema.index({ product: 1, isDeleted: 1 });
insurancePlanSchema.index({ product: 1, isActive: 1, isDeleted: 1 });

insurancePlanSchema.pre(/^find/, function (next) {
  if (this.getQuery().includeDeleted !== true) {
    this.where({ isDeleted: false });
  }
  next();
});

module.exports = mongoose.model('InsurancePlan', insurancePlanSchema);
