const mongoose = require('mongoose');

const applicationFieldValueSchema = new mongoose.Schema(
  {
    application: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'InsuranceApplication',
      required: [true, 'Application is required'],
      index: true,
    },
    productField: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ProductField',
      required: [true, 'Product field is required'],
      index: true,
    },
    fieldName: {
      type: String,
      required: [true, 'Field name is required'],
      trim: true,
    },
    fieldValue: {
      type: mongoose.Schema.Types.Mixed,
      required: [true, 'Field value is required'],
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

applicationFieldValueSchema.index({ application: 1, isDeleted: 1 });
applicationFieldValueSchema.index({ application: 1, productField: 1 });

module.exports = mongoose.model('ApplicationFieldValue', applicationFieldValueSchema);
