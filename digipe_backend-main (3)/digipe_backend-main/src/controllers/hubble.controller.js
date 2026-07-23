const hubbleService = require('../services/hubble.service');
const HubbleTransaction = require('../models/hubbleTransaction.model');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');

/**
 * GET /api/hubble/sdk-token
 * Generates a Hubble SSO token and returns the SDK URL for the authenticated user.
 * The frontend embeds this URL in a WebView (inside the app).
 */
const getHubbleSDKToken = asyncHandler(async (req, res) => {
  const { token, sdkUrl } = hubbleService.generateSSOToken(req.user);

  return ApiResponse.ok(res, messages.HUBBLE.SDK_TOKEN_GENERATED, {
    token,
    sdkUrl,
    clientId: require('../config/env').hubble.clientId,
  });
});

/**
 * GET /api/hubble/transactions
 * Returns the authenticated user's Hubble transaction history (stored via webhook).
 */
const getMyTransactions = asyncHandler(async (req, res) => {
  const transactions = await HubbleTransaction.find({ userId: req.user._id })
    .sort({ createdAt: -1 })
    .limit(100)
    .lean();

  return ApiResponse.ok(res, 'Transactions fetched', { transactions });
});

module.exports = {
  getHubbleSDKToken,
  getMyTransactions,
};
