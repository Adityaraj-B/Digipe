const mongoose = require('mongoose');
const { LOGIN_STATUS } = require('../constants');

const loginLogSchema = new mongoose.Schema(
  {
    sessionId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null, // null for failed logins with unknown users
    },
    identifier: {
      type: String,
      required: true,
      trim: true,
    },
    role: {
      type: String,
      default: null, // Display role at time of login (ADMIN / USER)
    },
    status: {
      type: String,
      enum: Object.values(LOGIN_STATUS),
      required: true,
      index: true,
    },
    failReason: {
      type: String,
      default: null,
    },
    ipAddress: {
      type: String,
      default: null,
    },
    userAgent: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true, // createdAt serves as the login timestamp
  }
);

loginLogSchema.index({ createdAt: -1 });
loginLogSchema.index({ identifier: 1, createdAt: -1 });

loginLogSchema.methods.toJSON = function () {
  const log = this.toObject();
  delete log.__v;
  return log;
};

module.exports = mongoose.model('LoginLog', loginLogSchema);
