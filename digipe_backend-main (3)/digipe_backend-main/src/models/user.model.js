const mongoose = require('mongoose');
const { ROLES } = require('../constants');
const { normalizePhone } = require('../utils/helpers');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      trim: true,
      maxlength: 100,
      default: null,
    },
    mobileNumber: {
      type: String,
      trim: true,
      sparse: true,
      index: true,
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
      default: null,
      sparse: true,
    },
    role: {
      type: String,
      enum: Object.values(ROLES),
      default: ROLES.CUSTOMER,
      index: true,
    },
    profileImage: {
      type: String,
      default: null,
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
    // ── Hubble / Location / Notifications ──────────────
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        default: [0, 0],
      },
      city: {
        type: String,
        trim: true,
        default: null,
      },
      state: {
        type: String,
        trim: true,
        default: null,
      },
      lastUpdated: {
        type: Date,
        default: null,
      },
    },
    pushTokens: [
      {
        token: { type: String, required: true },
        platform: {
          type: String,
          enum: ['web', 'android', 'ios'],
          default: 'web',
        },
        createdAt: { type: Date, default: Date.now },
      },
    ],
    notificationPreferences: {
      coupons: { type: Boolean, default: true },
      deals: { type: Boolean, default: true },
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Normalize mobileNumber to +91XXXXXXXXXX before every save
userSchema.pre('save', function (next) {
  if (this.mobileNumber && this.isModified('mobileNumber')) {
    this.mobileNumber = normalizePhone(this.mobileNumber);
  }
  next();
});

userSchema.index({ mobileNumber: 1, isDeleted: 1 });
userSchema.index({ email: 1, isDeleted: 1 });

userSchema.pre(/^find/, function (next) {
  if (this.getQuery().includeDeleted !== true) {
    this.where({ isDeleted: false });
  }
  next();
});

userSchema.methods.toJSON = function () {
  const user = this.toObject();
  delete user.__v;
  delete user.isDeleted;
  delete user.deletedAt;
  return user;
};

module.exports = mongoose.model('User', userSchema);
