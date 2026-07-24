const adminOrderService = require('../services/adminOrder.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');

class AdminOrderController {
  /**
   * Get all orders
   * @route GET /api/admin/orders
   * @access Private/Admin
   */
  getOrders = asyncHandler(async (req, res) => {
    const result = await adminOrderService.getAllOrders(req.query);
    return ApiResponse.ok(res, 'Orders fetched successfully', result);
  });

  /**
   * Get detailed order view
   * @route GET /api/admin/orders/:id
   * @access Private/Admin
   */
  getOrderDetail = asyncHandler(async (req, res) => {
    const result = await adminOrderService.getOrderDetail(req.params.id);
    return ApiResponse.ok(res, 'Order details fetched successfully', result);
  });

  /**
   * Update order status
   * @route PATCH /api/admin/orders/:id/status
   * @access Private/Admin
   */
  updateOrderStatus = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;
    const order = await adminOrderService.updateOrderStatus(id, status);
    return ApiResponse.ok(res, 'Order status updated successfully', order);
  });

  /**
   * Delete an order (soft delete)
   * @route DELETE /api/admin/orders/:id
   * @access Private/Admin
   */
  deleteOrder = asyncHandler(async (req, res) => {
    const result = await adminOrderService.deleteOrder(req.params.id);
    return ApiResponse.ok(res, result.message);
  });
}

module.exports = new AdminOrderController();
