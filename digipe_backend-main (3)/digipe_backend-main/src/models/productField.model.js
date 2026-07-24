const mongoose = require('mongoose');
const { FIELD_TYPES } = require('../constants');

const productFieldSchema = new mongoose.Schema(
  {
    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'InsuranceProduct',
      required: [true, 'Product is required'],
      index: true,
    },
    fieldName: {
      type: String,
      required: [true, 'Field name is required'],
      trim: true,
      maxlength: 100,
    },
    fieldLabel: {
      type: String,
      required: [true, 'Field label is required'],
      trim: true,
      maxlength: 200,
    },
    fieldType: {
      type: String,
      required: [true, 'Field type is required'],
      enum: Object.values(FIELD_TYPES),
    },
    placeholder: {
      type: String,
      trim: true,
      maxlength: 200,
      default: null,
    },
    isRequired: {
      type: Boolean,
      default: false,
    },
    validationRules: {
      min: { type: Number, default: null },
      max: { type: Number, default: null },
      minLength: { type: Number, default: null },
      maxLength: { type: Number, default: null },
      pattern: { type: String, default: null },
    },
    sortOrder: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
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

productFieldSchema.index({ product: 1, isDeleted: 1 });
productFieldSchema.index({ product: 1, sortOrder: 1, isDeleted: 1 });

productFieldSchema.pre(/^find/, function (next) {
  if (this.getQuery().includeDeleted !== true) {
    this.where({ isDeleted: false });
  }
  next();
});

productFieldSchema.virtual('options', {
  ref: 'FieldOption',
  localField: '_id',
  foreignField: 'productField',
});

module.exports = mongoose.model('ProductField', productFieldSchema);
