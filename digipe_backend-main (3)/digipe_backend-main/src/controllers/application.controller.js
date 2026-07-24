const applicationService = require('../services/application.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');
const { parsePaginationQuery } = require('../utils/pagination');

const create = asyncHandler(async (req, res) => {
  const application = await applicationService.create(req.user._id, req.body);
  return ApiResponse.created(res, messages.APPLICATION.CREATED, application);
});

const getMyApplications = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query, ['status']);
  const result = await applicationService.getMyApplications(req.user._id, options);
  return ApiResponse.ok(res, messages.APPLICATION.FETCHED, result.applications, result.meta);
});

const getAll = asyncHandler(async (req, res) => {
  const { filter, options } = parsePaginationQuery(req.query, ['status', 'user', 'product']);
  const result = await applicationService.getAll(filter, options);
  return ApiResponse.ok(res, messages.APPLICATION.FETCHED, result.applications, result.meta);
});

const getById = asyncHandler(async (req, res) => {
  const application = await applicationService.getById(req.params.id);
  return ApiResponse.ok(res, messages.APPLICATION.FETCHED_ONE, application);
});

const updateStatus = asyncHandler(async (req, res) => {
  const application = await applicationService.updateStatus(req.params.id, req.body, req.user._id);
  return ApiResponse.ok(res, messages.APPLICATION.STATUS_UPDATED, application);
});

module.exports = {
  create,
  getMyApplications,
  getAll,
  getById,
  updateStatus,
};
