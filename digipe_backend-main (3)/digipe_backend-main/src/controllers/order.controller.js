const orderService = require('../services/order.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');
const { parsePaginationQuery } = require('../utils/pagination');

const createOrder = asyncHandler(async (req, res) => {
  const order = await orderService.createOrder(req.user._id, req.body.items);
  return ApiResponse.created(res, messages.ORDER.CREATED, order);
});

const getMyOrders = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query, ['status', 'paymentStatus']);
  const result = await orderService.getMyOrders(req.user._id, options);
  return ApiResponse.ok(res, messages.ORDER.FETCHED, result.orders, result.meta);
});

const getAll = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query, ['status', 'paymentStatus', 'user']);
  const result = await orderService.getAll(filter, options);
  return ApiResponse.ok(res, messages.ORDER.FETCHED, result.orders, result.meta);
});

const getById = asyncHandler(async (req, res) => {
  const order = await orderService.getById(req.params.id);
  return ApiResponse.ok(res, messages.ORDER.FETCHED_ONE, order);
});

module.exports = {
  createOrder,
  getMyOrders,
  getAll,
  getById,
};