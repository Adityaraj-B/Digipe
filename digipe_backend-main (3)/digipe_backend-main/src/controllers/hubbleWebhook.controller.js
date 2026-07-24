const HubbleTransaction = require('../models/hubbleTransaction.model');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');
const logger = require('../config/logger');

/**
 * POST /api/hubble/webhook
 * Receives webhook events from Hubble SDK.
 * These can be payment_success, voucher_generated, refund, etc.
 *
 * Note: In production, you should verify the webhook signature
 * using a shared secret provided by Hubble during onboarding.
 */
const handleWebhook = asyncHandler(async (req, res) => {
  const payload = req.body;

  logger.info(`Hubble webhook received: ${JSON.stringify(payload).slice(0, 500)}`);

  // Extract event details from the webhook payload
  const {
    event,
    type,
    transactionId,
    userId: hubbleUserId,
    amount,
    brand,
    voucherCode,
    status,
    ...rest
  } = payload;

  const eventType = event || type || 'other';

  // Try to find the DigiPe user by the Hubble sub (which we set to user._id in SSO)
  let digiPeUserId = null;
  if (hubbleUserId) {
    // The `sub` claim in the SSO token was set to user._id
    const mongoose = require('mongoose');
    if (mongoose.Types.ObjectId.isValid(hubbleUserId)) {
      digiPeUserId = hubbleUserId;
    }
  }

  // Store the transaction
  const transaction = await HubbleTransaction.create({
    userId: digiPeUserId,
    hubbleTransactionId: transactionId || null,
    eventType: mapEventType(eventType),
    brand: brand || null,
    amount: amount || 0,
    voucherCode: voucherCode || null,
    status: mapStatus(status || eventType),
    rawPayload: payload,
    metadata: rest,
  });

  logger.info(`Hubble transaction saved: ${transaction._id} (type: ${eventType})`);

  return ApiResponse.ok(res, messages.HUBBLE.WEBHOOK_RECEIVED, {
    transactionId: transaction._id,
  });
});

/**
 * Maps Hubble event type strings to our enum values.
 */
const mapEventType = (event) => {
  const mapping = {
    payment_initiated: 'payment_initiated',
    payment_success: 'payment_success',
    payment_failed: 'payment_failed',
    voucher_generated: 'voucher_generated',
    voucher_redeemed: 'voucher_redeemed',
    order_placed: 'order_placed',
    refund_initiated: 'refund_initiated',
    refund_completed: 'refund_completed',
  };
  return mapping[event] || 'other';
};

/**
 * Maps Hubble status strings to our status enum.
 */
const mapStatus = (status) => {
  if (status === 'payment_success' || status === 'voucher_generated' || status === 'completed') {
    return 'completed';
  }
  if (status === 'payment_failed' || status === 'failed') {
    return 'failed';
  }
  if (status === 'refund_completed' || status === 'refunded') {
    return 'refunded';
  }
  return 'pending';
};

module.exports = {
  handleWebhook,
};
