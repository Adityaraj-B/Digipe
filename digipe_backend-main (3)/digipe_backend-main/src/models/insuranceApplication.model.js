const mongoose = require('mongoose');
const { APPLICATION_STATUS } = require('../constants');

const insuranceApplicationSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
      index: true,
    },
    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'InsuranceProduct',
      required: [true, 'Product is required'],
      index: true,
    },
    plan: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'InsurancePlan',
      required: [true, 'Plan is required'],
      index: true,
    },
    applicationNumber: {
      type: String,
      unique: true,
      index: true,
    },
    status: {
      type: String,
      enum: Object.values(APPLICATION_STATUS),
      default: APPLICATION_STATUS.SUBMITTED,
      index: true,
    },
    remarks: {
      type: String,
      trim: true,
      maxlength: 2000,
      default: null,
    },
    reviewedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    reviewedAt: {
      type: Date,
      default: null,
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

insuranceApplicationSchema.index({ user: 1, isDeleted: 1 });
insuranceApplicationSchema.index({ user: 1, plan: 1, isDeleted: 1 });
insuranceApplicationSchema.index({ status: 1, isDeleted: 1 });

insuranceApplicationSchema.pre(/^find/, function (next) {
  if (this.getQuery().includeDeleted !== true) {
    this.where({ isDeleted: false });
  }
  next();
});

insuranceApplicationSchema.virtual('fieldValues', {
  ref: 'ApplicationFieldValue',
  localField: '_id',
  foreignField: 'application',
});

module.exports = mongoose.model('InsuranceApplication', insuranceApplicationSchema);
