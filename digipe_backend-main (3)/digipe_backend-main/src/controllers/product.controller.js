const productService = require('../services/product.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');
const { parsePaginationQuery } = require('../utils/pagination');

const create = asyncHandler(async (req, res) => {
  const product = await productService.create(req.body, req.user._id);
  return ApiResponse.created(res, messages.PRODUCT.CREATED, product);
});

const getAll = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query, ['category', 'isActive']);
  const result = await productService.getAll(filter, options);
  return ApiResponse.ok(res, messages.PRODUCT.FETCHED, result.products, result.meta);
});

const getById = asyncHandler(async (req, res) => {
  const product = await productService.getById(req.params.id);
  return ApiResponse.ok(res, messages.PRODUCT.FETCHED_ONE, product);
});

const getByCategory = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query);
  const result = await productService.getByCategory(req.params.categoryId, options);
  return ApiResponse.ok(res, messages.PRODUCT.FETCHED, result.products, result.meta);
});

const update = asyncHandler(async (req, res) => {
  const product = await productService.update(req.params.id, req.body, req.user._id);
  return ApiResponse.ok(res, messages.PRODUCT.UPDATED, product);
});

const remove = asyncHandler(async (req, res) => {
  const result = await productService.delete(req.params.id, req.user._id);
  return ApiResponse.ok(res, result.message);
});

module.exports = {
  create,
  getAll,
  getById,
  getByCategory,
  update,
  remove,
};
