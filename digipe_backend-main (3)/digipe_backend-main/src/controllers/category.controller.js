const categoryService = require('../services/category.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');
const { parsePaginationQuery } = require('../utils/pagination');

const create = asyncHandler(async (req, res) => {
  const category = await categoryService.create(req.body, req.user._id);
  return ApiResponse.created(res, messages.CATEGORY.CREATED, category);
});

const getAll = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query, ['isActive']);
  const result = await categoryService.getAll(filter, options);
  return ApiResponse.ok(res, messages.CATEGORY.FETCHED, result.categories, result.meta);
});

const getById = asyncHandler(async (req, res) => {
  const category = await categoryService.getById(req.params.id);
  return ApiResponse.ok(res, messages.CATEGORY.FETCHED_ONE, category);
});

const update = asyncHandler(async (req, res) => {
  const category = await categoryService.update(req.params.id, req.body, req.user._id);
  return ApiResponse.ok(res, messages.CATEGORY.UPDATED, category);
});

const remove = asyncHandler(async (req, res) => {
  const result = await categoryService.delete(req.params.id, req.user._id);
  return ApiResponse.ok(res, result.message);
});

module.exports = {
  create,
  getAll,
  getById,
  update,
  remove,
};
