const paymentService = require('../services/payment.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');
const logger = require('../config/logger');

const createPayment = asyncHandler(async (req, res) => {
  const result = await paymentService.createPayment(req.user._id, req.body);
  return ApiResponse.created(res, messages.PAYMENT.SESSION_CREATED, result);
});

const verifyPayment = asyncHandler(async (req, res) => {
  const payment = await paymentService.verifyPayment(req.params.orderId);
  return ApiResponse.ok(res, messages.PAYMENT.VERIFIED, payment);
});

const handleWebhook = asyncHandler(async (req, res) => {
  logger.info('Cashfree webhook received', { eventType: req.body?.type });
  const result = await paymentService.handleWebhook(req.body, req.headers, req.rawBody);
  return ApiResponse.ok(res, messages.PAYMENT.WEBHOOK_RECEIVED, result);
});

const getById = asyncHandler(async (req, res) => {
  const payment = await paymentService.getById(req.params.id);
  return ApiResponse.ok(res, messages.PAYMENT.FETCHED, payment);
});

const getByOrder = asyncHandler(async (req, res) => {
  const payment = await paymentService.getByOrder(req.params.orderId);
  return ApiResponse.ok(res, messages.PAYMENT.FETCHED, payment);
});

module.exports = {
  createPayment,
  verifyPayment,
  handleWebhook,
  getById,
  getByOrder,
};
