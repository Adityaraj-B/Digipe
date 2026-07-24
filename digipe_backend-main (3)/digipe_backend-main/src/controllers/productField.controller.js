const productFieldService = require('../services/productField.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');

const create = asyncHandler(async (req, res) => {
  const field = await productFieldService.create(req.body, req.user._id);
  return ApiResponse.created(res, messages.PRODUCT_FIELD.CREATED, field);
});

const getByProduct = asyncHandler(async (req, res) => {
  const fields = await productFieldService.getByProduct(req.params.productId);
  return ApiResponse.ok(res, messages.PRODUCT_FIELD.FETCHED, fields);
});

const update = asyncHandler(async (req, res) => {
  const field = await productFieldService.update(req.params.id, req.body, req.user._id);
  return ApiResponse.ok(res, messages.PRODUCT_FIELD.UPDATED, field);
});

const remove = asyncHandler(async (req, res) => {
  const result = await productFieldService.delete(req.params.id, req.user._id);
  return ApiResponse.ok(res, result.message);
});

module.exports = {
  create,
  getByProduct,
  update,
  remove,
};
