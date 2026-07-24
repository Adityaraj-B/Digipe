const mongoose = require('mongoose');
const { DOCUMENT_TYPES } = require('../constants');

const claimDocumentSchema = new mongoose.Schema(
  {
    claim: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Claim',
      required: [true, 'Claim is required'],
      index: true,
    },
    document: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Document',
      required: [true, 'Document is required'],
    },
    documentType: {
      type: String,
      enum: Object.values(DOCUMENT_TYPES),
      default: DOCUMENT_TYPES.OTHER,
    },
    isDeleted: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

claimDocumentSchema.index({ claim: 1, isDeleted: 1 });

module.exports = mongoose.model('ClaimDocument', claimDocumentSchema);
