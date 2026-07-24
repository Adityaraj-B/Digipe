const planService = require('../services/plan.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');
const { parsePaginationQuery } = require('../utils/pagination');

const create = asyncHandler(async (req, res) => {
  const plan = await planService.create(req.body, req.user._id);
  return ApiResponse.created(res, messages.PLAN.CREATED, plan);
});

const getAll = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query, ['product']);
  const result = await planService.getAll(filter, options);
  return ApiResponse.ok(res, messages.PLAN.FETCHED, result.plans, result.meta);
});

const getById = asyncHandler(async (req, res) => {
  const plan = await planService.getById(req.params.id);
  return ApiResponse.ok(res, messages.PLAN.FETCHED_ONE, plan);
});

const getByProduct = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query);
  const result = await planService.getByProduct(req.params.productId, options);
  return ApiResponse.ok(res, messages.PLAN.FETCHED, result.plans, result.meta);
});

const update = asyncHandler(async (req, res) => {
  const plan = await planService.update(req.params.id, req.body, req.user._id);
  return ApiResponse.ok(res, messages.PLAN.UPDATED, plan);
});

const remove = asyncHandler(async (req, res) => {
  const result = await planService.delete(req.params.id, req.user._id);
  return ApiResponse.ok(res, result.message);
});

module.exports = {
  create,
  getAll,
  getById,
  getByProduct,
  update,
  remove,
};
