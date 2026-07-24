const mongoose = require('mongoose');

const consentSchema = new mongoose.Schema(
  {
    application: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'InsuranceApplication',
      required: [true, 'Application is required'],
      index: true,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
      index: true,
    },
    adminUser: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Admin user is required'],
    },
    userConsent: {
      type: Boolean,
      default: false,
    },
    adminApproval: {
      type: Boolean,
      default: true,
    },
    consentTimestamp: {
      type: Date,
      default: null,
    },
    approvalTimestamp: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

consentSchema.index({ application: 1, user: 1 });

module.exports = mongoose.model('Consent', consentSchema);
