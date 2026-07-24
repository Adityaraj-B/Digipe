const locationService = require('../services/location.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');

/**
 * PUT /api/users/location
 * Updates the authenticated user's GPS location.
 * Frontend should call this after getting navigator.geolocation.getCurrentPosition().
 */
const updateLocation = asyncHandler(async (req, res) => {
  const { latitude, longitude } = req.body;
  const result = await locationService.updateUserLocation(req.user._id, latitude, longitude);
  return ApiResponse.ok(res, messages.LOCATION.UPDATED, result);
});

/**
 * POST /api/users/push-token
 * Registers a device push notification token (FCM).
 * Frontend should call this after obtaining the FCM token.
 */
const registerPushToken = asyncHandler(async (req, res) => {
  const { token, platform } = req.body;
  await locationService.registerPushToken(req.user._id, token, platform || 'web');
  return ApiResponse.ok(res, messages.LOCATION.PUSH_TOKEN_REGISTERED);
});

/**
 * DELETE /api/users/push-token
 * Removes a device push notification token.
 */
const removePushToken = asyncHandler(async (req, res) => {
  const { token } = req.body;
  await locationService.removePushToken(req.user._id, token);
  return ApiResponse.ok(res, messages.LOCATION.PUSH_TOKEN_REMOVED);
});

module.exports = {
  updateLocation,
  registerPushToken,
  removePushToken,
};
