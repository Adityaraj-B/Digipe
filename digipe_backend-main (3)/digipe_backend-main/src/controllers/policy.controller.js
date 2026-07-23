const policyService = require('../services/policy.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');
const { parsePaginationQuery } = require('../utils/pagination');

const getMyPolicies = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query, ['status']);
  const result = await policyService.getMyPolicies(req.user._id, options);
  return ApiResponse.ok(res, messages.POLICY.FETCHED, result.policies, result.meta);
});

const getAll = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query, ['status', 'user']);
  const result = await policyService.getAll(filter, options);
  return ApiResponse.ok(res, messages.POLICY.FETCHED, result.policies, result.meta);
});

const getById = asyncHandler(async (req, res) => {
  const policy = await policyService.getById(req.params.id);
  return ApiResponse.ok(res, messages.POLICY.FETCHED_ONE, policy);
});

module.exports = {
  getMyPolicies,
  getAll,
  getById,
};
