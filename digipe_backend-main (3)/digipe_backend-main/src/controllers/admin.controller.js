const adminService = require('../services/admin.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');

const getDashboard = asyncHandler(async (req, res) => {
  const { productId } = req.query;
  const dashboardData = await adminService.getDashboardData(productId);
  return ApiResponse.ok(res, 'Admin dashboard statistics retrieved successfully', dashboardData);
});

module.exports = {
  getDashboard,
};
