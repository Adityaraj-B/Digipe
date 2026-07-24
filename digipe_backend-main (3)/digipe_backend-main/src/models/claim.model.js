const mongoose = require('mongoose');
const { CLAIM_STATUS } = require('../constants');

const claimSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
      index: true,
    },
    policy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Policy',
      required: [true, 'Policy is required'],
      index: true,
    },
    claimNumber: {
      type: String,
      unique: true,
      index: true,
    },
    description: {
      type: String,
      required: [true, 'Claim description is required'],
      trim: true,
      maxlength: 5000,
    },
    reason: {
      type: String,
      trim: true,
      maxlength: 2000,
      default: null,
    },
    incidentDate: {
      type: Date,
      default: null,
    },
    claimAmount: {
      type: Number,
      required: [true, 'Claim amount is required'],
      min: 0,
    },
    status: {
      type: String,
      enum: Object.values(CLAIM_STATUS),
      default: CLAIM_STATUS.SUBMITTED,
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
    settledAmount: {
      type: Number,
      default: null,
      min: 0,
    },
    settledAt: {
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

claimSchema.index({ user: 1, isDeleted: 1 });
claimSchema.index({ policy: 1, isDeleted: 1 });
claimSchema.index({ status: 1, isDeleted: 1 });

claimSchema.pre(/^find/, function (next) {
  if (this.getQuery().includeDeleted !== true) {
    this.where({ isDeleted: false });
  }
  next();
});

claimSchema.virtual('documents', {
  ref: 'ClaimDocument',
  localField: '_id',
  foreignField: 'claim',
});

module.exports = mongoose.model('Claim', claimSchema);
