const claimService = require('../services/claim.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');
const { parsePaginationQuery } = require('../utils/pagination');

const create = asyncHandler(async (req, res) => {
  const claim = await claimService.create(req.user._id, req.body);
  return ApiResponse.created(res, messages.CLAIM.CREATED, claim);
});

const getMyClaims = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query, ['status']);
  const result = await claimService.getMyClaims(req.user._id, options);
  return ApiResponse.ok(res, messages.CLAIM.FETCHED, result.claims, result.meta);
});

const getAll = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query, ['status', 'user', 'policy']);
  const result = await claimService.getAll(filter, options);
  return ApiResponse.ok(res, messages.CLAIM.FETCHED, result.claims, result.meta);
});

const getById = asyncHandler(async (req, res) => {
  const claim = await claimService.getById(req.params.id);
  return ApiResponse.ok(res, messages.CLAIM.FETCHED_ONE, claim);
});

const addDocument = asyncHandler(async (req, res) => {
  const result = await claimService.addDocument(req.params.id, req.body, req.user._id);
  return ApiResponse.ok(res, messages.CLAIM.DOCUMENT_ADDED, result);
});

const updateStatus = asyncHandler(async (req, res) => {
  const claim = await claimService.updateStatus(req.params.id, req.body, req.user._id);
  return ApiResponse.ok(res, messages.CLAIM.STATUS_UPDATED, claim);
});

module.exports = {
  create,
  getMyClaims,
  getAll,
  getById,
  addDocument,
  updateStatus,
};
