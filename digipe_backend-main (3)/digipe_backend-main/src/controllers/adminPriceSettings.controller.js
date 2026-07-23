const adminPriceSettingsService = require('../services/adminPriceSettings.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');

const getSettings = asyncHandler(async (req, res) => {
  const settings = await adminPriceSettingsService.getSettings();
  return ApiResponse.ok(res, messages.PRICE_SETTINGS.FETCHED, settings);
});

const updatePromotionalDiscount = asyncHandler(async (req, res) => {
  const settings = await adminPriceSettingsService.updatePromotionalDiscount(req.body, req.user._id);
  return ApiResponse.ok(res, messages.PRICE_SETTINGS.DISCOUNT_UPDATED, settings);
});

const updateTax = asyncHandler(async (req, res) => {
  const settings = await adminPriceSettingsService.updateTax(req.body, req.user._id);
  return ApiResponse.ok(res, messages.PRICE_SETTINGS.TAX_UPDATED, settings);
});

module.exports = {
  getSettings,
  updatePromotionalDiscount,
  updateTax,
};
