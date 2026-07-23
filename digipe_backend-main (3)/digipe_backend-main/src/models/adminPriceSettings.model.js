const mongoose = require('mongoose');

const adminPriceSettingsSchema = new mongoose.Schema(
  {
    promotionalDiscount: {
      percentage: {
        type: Number,
        default: 0,
        min: 0,
        max: 100,
      },
      isActive: {
        type: Boolean,
        default: false,
      },
    },
    tax: {
      gstPercentage: {
        type: Number,
        default: 18,
        min: 0,
        max: 100,
      },
    },
    updatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('AdminPriceSettings', adminPriceSettingsSchema);
