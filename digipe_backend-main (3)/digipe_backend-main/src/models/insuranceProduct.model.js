const mongoose = require('mongoose');

const insuranceProductSchema = new mongoose.Schema(
  {
    category: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'InsuranceCategory',
      required: [true, 'Category is required'],
      index: true,
    },
    name: {
      type: String,
      required: [true, 'Product name is required'],
      trim: true,
      maxlength: 200,
    },
    slug: {
      type: String,
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    description: {
      type: String,
      trim: true,
      maxlength: 5000,
      default: null,
    },
    shortDescription: {
      type: String,
      trim: true,
      maxlength: 500,
      default: null,
    },
    image: {
      type: String,
      default: null,
    },
    features: [
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

insuranceProductSchema.index({ category: 1, isDeleted: 1 });
insuranceProductSchema.index({ name: 1, isDeleted: 1 });
insuranceProductSchema.index({ slug: 1, isDeleted: 1 });

insuranceProductSchema.pre(/^find/, function (next) {
  if (this.getQuery().includeDeleted !== true) {
    this.where({ isDeleted: false });
  }
  next();
});

insuranceProductSchema.virtual('plans', {
  ref: 'InsurancePlan',
  localField: '_id',
  foreignField: 'product',
});

insuranceProductSchema.virtual('fields', {
  ref: 'ProductField',
  localField: '_id',
  foreignField: 'product',
});

module.exports = mongoose.model('InsuranceProduct', insuranceProductSchema);
