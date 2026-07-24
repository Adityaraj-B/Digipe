const adminLoginService = require('../services/adminLogin.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');

const getLogins = asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page, 10) || 1;
  const limit = parseInt(req.query.limit, 10) || 5;

  const result = await adminLoginService.getLogins(page, limit);

  return ApiResponse.ok(res, messages.AUTH.LOGIN_LOGS_FETCHED, result.logins, {
    totalDocs: result.totalDocs,
    totalPages: result.totalPages,
    currentPage: result.currentPage,
    limit: result.limit,
  });
});

module.exports = {
  getLogins,
};
