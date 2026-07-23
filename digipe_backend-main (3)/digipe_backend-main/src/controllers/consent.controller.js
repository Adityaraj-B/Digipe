const consentService = require('../services/consent.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');

const getConsent = asyncHandler(async (req, res) => {
  const consent = await consentService.getByApplication(req.params.id);
  return ApiResponse.ok(res, messages.CONSENT.FETCHED, consent);
});

const recordUserConsent = asyncHandler(async (req, res) => {
  const consent = await consentService.recordUserConsent(req.params.id, req.user._id);
  return ApiResponse.ok(res, messages.CONSENT.USER_CONSENT_RECORDED, consent);
});

module.exports = {
  getConsent,
  recordUserConsent,
};
