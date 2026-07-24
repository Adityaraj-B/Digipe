const mongoose = require('mongoose');

const fieldOptionSchema = new mongoose.Schema(
  {
    productField: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ProductField',
      required: [true, 'Product field is required'],
      index: true,
    },
    label: {
      type: String,
      required: [true, 'Option label is required'],
      trim: true,
      maxlength: 200,
    },
    value: {
      type: String,
      required: [true, 'Option value is required'],
      trim: true,
      maxlength: 200,
    },
    sortOrder: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

fieldOptionSchema.index({ productField: 1, isActive: 1 });
fieldOptionSchema.index({ productField: 1, sortOrder: 1 });

module.exports = mongoose.model('FieldOption', fieldOptionSchema);
