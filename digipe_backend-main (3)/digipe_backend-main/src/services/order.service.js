const orderRepository = require('../repositories/order.repository');
const orderItemRepository = require('../repositories/orderItem.repository');
const planRepository = require('../repositories/plan.repository');
const applicationRepository = require('../repositories/application.repository');
const adminPriceSettingsService = require('./adminPriceSettings.service');
const auditLogService = require('./auditLog.service');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const { generateOrderNumber } = require('../utils/helpers');
const { buildPaginationMeta } = require('../utils/pagination');
const { AUDIT_ACTIONS, APPLICATION_STATUS } = require('../constants');

class OrderService {
  /**
   * Create an order directly from an array of { planId, applicationId } items.
   * Applies admin-configured promotional discount and GST.
   */
  async createOrder(userId, items) {
    if (!items || items.length === 0) {
      throw ApiError.badRequest('At least one item is required to create an order');
    }

    let subtotal = 0;
    const orderItemsData = [];
    const seenPlanIds = new Set();
    let primaryApplicationId = null;

    for (const item of items) {
      const { planId, applicationId } = item;

      if (seenPlanIds.has(planId.toString())) {
        throw ApiError.badRequest('Duplicate plan found in order items');
      }
      seenPlanIds.add(planId.toString());

      const plan = await planRepository.findById(planId);
      if (!plan) {
        throw ApiError.notFound(messages.PLAN.NOT_FOUND);
      }

      const application = await applicationRepository.findById(applicationId);
      if (!application) {
        throw ApiError.notFound(messages.APPLICATION.NOT_FOUND);
      }

      if (application.user.toString() !== userId.toString()) {
        throw ApiError.forbidden(messages.APPLICATION.NOT_OWNED);
      }

      if (application.status !== APPLICATION_STATUS.APPROVED) {
        throw ApiError.badRequest(messages.APPLICATION.NOT_APPROVED);
      }

      if (!primaryApplicationId) {
        primaryApplicationId = application._id;
      }

      subtotal += plan.premium;
      orderItemsData.push({
        plan: plan._id,
        application: application._id,
        premium: plan.premium,
        coverageAmount: plan.coverageAmount,
      });
    }

    // Calculate price breakdown with admin-configured discount and GST
    const priceBreakdown = await adminPriceSettingsService.calculateFinalAmount(subtotal);

    const order = await orderRepository.create({
      user: userId,
      orderNumber: generateOrderNumber(),
      application: primaryApplicationId,
      subtotal: priceBreakdown.subtotal,
      discountPercentage: priceBreakdown.discountPercentage,
      discountAmount: priceBreakdown.discountAmount,
      gstPercentage: priceBreakdown.gstPercentage,
      taxAmount: priceBreakdown.taxAmount,
      totalAmount: priceBreakdown.totalAmount,
    });

    const orderItems = orderItemsData.map((item) => ({
      ...item,
      order: order._id,
    }));
    await orderItemRepository.createMany(orderItems);

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.CREATE,
      entityType: 'Order',
      entityId: order._id,
      newData: {
        orderNumber: order.orderNumber,
        subtotal: priceBreakdown.subtotal,
        discountAmount: priceBreakdown.discountAmount,
        taxAmount: priceBreakdown.taxAmount,
        totalAmount: priceBreakdown.totalAmount,
        itemCount: orderItems.length,
      },
    });

    return orderRepository.findByIdWithDetails(order._id);
  }

  /**
   * Get customer's orders with pagination.
   */
  async getMyOrders(userId, options) {
    const { docs, totalDocs } = await orderRepository.findByUser(userId, options);
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { orders: docs, meta };
  }

  /**
   * Get all orders (admin) with pagination.
   */
  async getAll(filter, options) {
    const { docs, totalDocs } = await orderRepository.findWithPagination(filter, {
      ...options,
      populate: [
        { path: 'user', select: 'name mobileNumber email' },
        { path: 'items', populate: { path: 'plan', select: 'name premium coverageAmount' } },
      ],
    });
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { orders: docs, meta };
  }

  /**
   * Get a single order by ID with full details.
   */
  async getById(id) {
    const order = await orderRepository.findByIdWithDetails(id);
    if (!order) {
      throw ApiError.notFound(messages.ORDER.NOT_FOUND);
    }
    return order;
  }
}

module.exports = new OrderService();