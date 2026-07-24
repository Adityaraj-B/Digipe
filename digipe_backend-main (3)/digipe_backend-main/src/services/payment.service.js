const { cashfreeClient } = require('../config/cashfree');
const paymentRepository = require('../repositories/payment.repository');
const orderRepository = require('../repositories/order.repository');
const orderItemRepository = require('../repositories/orderItem.repository');
const policyRepository = require('../repositories/policy.repository');
const userRepository = require('../repositories/user.repository');
const applicationRepository = require('../repositories/application.repository');
const auditLogService = require('./auditLog.service');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const logger = require('../config/logger');
const env = require('../config/env');
const { generateTransactionId, generatePolicyNumber } = require('../utils/helpers');
const { AUDIT_ACTIONS, ORDER_STATUS, PAYMENT_STATUS, PAYMENT_TRANSACTION_STATUS, PAYMENT_METHOD, APPLICATION_STATUS } = require('../constants');

class PaymentService {
  /**
   * Create a Cashfree payment order for the given internal order.
   * - Validates ownership and order status
   * - Verifies all linked applications are admin-approved
   * - Handles idempotency (returns existing session if PENDING payment exists)
   * - Creates a Cashfree order via PGCreateOrder
   * - Stores payment record with PENDING status
   * - Returns payment_session_id and cf_order_id for frontend checkout
   */
  async createPayment(userId, data) {
    const { orderId, paymentMethod } = data;

    const order = await orderRepository.findById(orderId);
    if (!order) {
      throw ApiError.notFound(messages.ORDER.NOT_FOUND);
    }

    if (order.user.toString() !== userId.toString()) {
      throw ApiError.forbidden(messages.AUTH.FORBIDDEN);
    }

    if (order.paymentStatus === PAYMENT_STATUS.PAID) {
      throw ApiError.conflict(messages.ORDER.ALREADY_PAID);
    }

    if (order.status === ORDER_STATUS.CANCELLED) {
      throw ApiError.badRequest(messages.ORDER.CANCELLED);
    }

    // ============================================================
    // ADMIN APPROVAL GATE — Payment blocked until all approved
    // ============================================================
    const orderItems = await orderItemRepository.findByOrder(orderId);
    for (const item of orderItems) {
      const application = await applicationRepository.findById(
        item.application?._id || item.application
      );
      if (!application || application.status !== APPLICATION_STATUS.APPROVED) {
        throw ApiError.forbidden(messages.PAYMENT.NOT_APPROVED);
      }
    }

    // ============================================================
    // IDEMPOTENCY: Return existing PENDING payment session
    // (only if session is still fresh — Cashfree sessions expire ~30 min)
    // ============================================================
    const existingPayment = await paymentRepository.findByOrder(orderId);
    if (existingPayment && existingPayment.status === PAYMENT_TRANSACTION_STATUS.SUCCESS) {
      throw ApiError.conflict(messages.PAYMENT.ALREADY_PAID);
    }

    if (existingPayment && existingPayment.status === PAYMENT_TRANSACTION_STATUS.PENDING && existingPayment.paymentSessionId) {
      const sessionAgeMs = Date.now() - new Date(existingPayment.createdAt).getTime();
      const SESSION_TTL_MS = 25 * 60 * 1000; // 25 minutes (Cashfree sessions expire at ~30 min)

      if (sessionAgeMs < SESSION_TTL_MS) {
        logger.info(`Returning existing payment session for order ${orderId} (age: ${Math.round(sessionAgeMs / 1000)}s)`);
        return {
          payment: existingPayment,
          paymentSessionId: existingPayment.paymentSessionId,
          cashfreeOrderId: existingPayment.cashfreeOrderId,
        };
      }

      // Session expired — mark old payment as FAILED so a fresh one is created below
      logger.info(`Payment session expired for order ${orderId} (age: ${Math.round(sessionAgeMs / 1000)}s), creating new session`);
      await paymentRepository.updateById(existingPayment._id, {
        status: PAYMENT_TRANSACTION_STATUS.FAILED,
        gatewayResponse: { ...existingPayment.gatewayResponse, _expiredBySystem: true },
      });
    }

    // If previous payment failed, reset order paymentStatus for retry
    if (existingPayment && existingPayment.status === PAYMENT_TRANSACTION_STATUS.FAILED) {
      logger.info(`Previous payment failed for order ${orderId}, allowing retry`);
      await orderRepository.updateById(orderId, {
        paymentStatus: PAYMENT_STATUS.PENDING,
      });
    }

    // ============================================================
    // CASHFREE ORDER CREATION
    // ============================================================
    const user = await userRepository.findById(userId);
    const cfOrderId = `cf_${order.orderNumber}_${Date.now()}`;

    const orderRequest = {
      order_amount: order.totalAmount,
      order_currency: 'INR',
      order_id: cfOrderId,
      customer_details: {
        customer_id: userId.toString(),
        customer_name: user?.name || 'Customer',
        customer_phone: user?.mobileNumber || '9999999999',
        customer_email: user?.email || 'customer@digipe.com',
      },
      order_meta: {
        return_url: `${env.frontendSuccessUrl}?order_id={order_id}`,
        notify_url: `https://${env.apiDomainName || 'api.digipe.in'}/api/payments/webhook`,
      },
      order_note: `Payment for order ${order.orderNumber}`,
    };

    logger.info(`Creating Cashfree order for internal order ${orderId}`, { cfOrderId });

    let cfResponse;
    try {
      const response = await cashfreeClient.PGCreateOrder(orderRequest);
      cfResponse = response.data;
      logger.info(`Cashfree order created successfully`, {
        cfOrderId: cfResponse.cf_order_id,
        paymentSessionId: cfResponse.payment_session_id,
      });
    } catch (error) {
      logger.error('Cashfree order creation failed', {
        error: error?.response?.data || error.message,
        orderId,
      });
      throw ApiError.internal(messages.PAYMENT.FAILED);
    }

    // ============================================================
    // STORE PAYMENT RECORD (PENDING)
    // ============================================================
    const transactionId = generateTransactionId();

    const payment = await paymentRepository.create({
      order: orderId,
      user: userId,
      amount: order.totalAmount,
      paymentMethod: paymentMethod || null,
      transactionId,
      cashfreeOrderId: cfOrderId,
      paymentSessionId: cfResponse.payment_session_id,
      gatewayResponse: cfResponse,
      status: PAYMENT_TRANSACTION_STATUS.PENDING,
    });

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.CREATE,
      entityType: 'Payment',
      entityId: payment._id,
      newData: { transactionId, cfOrderId, amount: order.totalAmount },
    });

    return {
      payment,
      paymentSessionId: cfResponse.payment_session_id,
      cashfreeOrderId: cfOrderId,
    };
  }

  /**
   * Verify payment status by querying Cashfree for the latest state.
   * Updates local records based on the Cashfree response.
   */
  async verifyPayment(orderId) {
    const payment = await paymentRepository.findByOrder(orderId);
    if (!payment) {
      throw ApiError.notFound(messages.PAYMENT.NOT_FOUND);
    }

    // If already settled locally, return current state
    if (payment.status === PAYMENT_TRANSACTION_STATUS.SUCCESS) {
      return payment;
    }

    // ============================================================
    // FETCH PAYMENT STATUS FROM CASHFREE
    // ============================================================
    let cfPayments;
    try {
      const response = await cashfreeClient.PGOrderFetchPayments(payment.cashfreeOrderId);
      cfPayments = response.data;
      logger.info(`Cashfree payment status fetched for ${payment.cashfreeOrderId}`, {
        paymentsCount: cfPayments?.length,
      });
    } catch (error) {
      logger.error('Cashfree payment status fetch failed', {
        error: error?.response?.data || error.message,
        cashfreeOrderId: payment.cashfreeOrderId,
      });
      throw ApiError.internal(messages.PAYMENT.VERIFICATION_FAILED);
    }

    // Process the latest payment attempt
    if (!cfPayments || cfPayments.length === 0) {
      logger.info(`No payment attempts found for ${payment.cashfreeOrderId}`);
      return payment;
    }

    // Find the successful payment or the latest one
    const successfulPayment = cfPayments.find((p) => p.payment_status === 'SUCCESS');
    const latestPayment = successfulPayment || cfPayments[cfPayments.length - 1];

    return this._processPaymentStatus(payment, latestPayment);
  }

  /**
   * Handle Cashfree webhook notifications.
   * Verifies signature and processes payment status updates.
   */
  async handleWebhook(body, headers, rawBody) {
    const timestamp = headers['x-cashfree-timestamp'] || headers['x-webhook-timestamp'];
    const signature = headers['x-cashfree-signature'] || headers['x-webhook-signature'];

    if (!timestamp || !signature) {
      logger.warn('Webhook received without signature headers');
      throw ApiError.badRequest('Missing webhook signature');
    }

    // ============================================================
    // VERIFY WEBHOOK SIGNATURE
    // ============================================================
    try {
      // Use the preserved raw body for accurate signature verification;
      // fall back to JSON.stringify only if rawBody is unavailable.
      const bodyForVerification = rawBody || (typeof body === 'string' ? body : JSON.stringify(body));
      cashfreeClient.PGVerifyWebhookSignature(signature, bodyForVerification, timestamp);
      logger.info('Webhook signature verified successfully');
    } catch (error) {
      logger.error('Webhook signature verification failed', { error: error.message });
      throw ApiError.unauthorized('Invalid webhook signature');
    }

    // ============================================================
    // PROCESS WEBHOOK DATA
    // ============================================================
    const webhookData = typeof body === 'string' ? JSON.parse(body) : body;
    const eventType = webhookData.type;
    const paymentData = webhookData.data?.payment;
    const orderData = webhookData.data?.order;

    if (!orderData?.order_id) {
      logger.warn('Webhook missing order_id', { eventType });
      return { status: 'ignored', reason: 'missing order_id' };
    }

    logger.info(`Processing webhook event: ${eventType}`, {
      cfOrderId: orderData.order_id,
      paymentStatus: paymentData?.payment_status,
    });

    const payment = await paymentRepository.findByCashfreeOrderId(orderData.order_id);
    if (!payment) {
      logger.warn(`Payment not found for Cashfree order: ${orderData.order_id}`);
      return { status: 'ignored', reason: 'payment not found' };
    }

    // Idempotency: skip if already processed as SUCCESS
    if (payment.status === PAYMENT_TRANSACTION_STATUS.SUCCESS) {
      logger.info(`Payment already processed for ${orderData.order_id}`);
      return { status: 'already_processed' };
    }

    if (paymentData) {
      await this._processPaymentStatus(payment, paymentData);
    }

    return { status: 'processed', orderId: orderData.order_id };
  }

  /**
   * Process payment status from Cashfree response and update local records.
   * @private
   */
  async _processPaymentStatus(payment, cfPaymentData) {
    const paymentStatus = cfPaymentData.payment_status;
    const rawPaymentGroup = cfPaymentData.payment_group;
    const validPaymentMethods = Object.values(PAYMENT_METHOD);
    const paymentMethod = rawPaymentGroup
      ? rawPaymentGroup.toUpperCase()
      : payment.paymentMethod;
    const orderId = payment.order?._id || payment.order;

    const updateData = {
      gatewayResponse: cfPaymentData,
    };

    if (paymentMethod && validPaymentMethods.includes(paymentMethod)) {
      updateData.paymentMethod = paymentMethod;
    } else if (paymentMethod) {
      logger.warn(`Unknown payment method from gateway: ${cfPaymentData.payment_group}`);
    }

    if (paymentStatus === 'SUCCESS') {
      updateData.status = PAYMENT_TRANSACTION_STATUS.SUCCESS;
      updateData.paidAt = new Date();

      await paymentRepository.updateById(payment._id, updateData);

      // Update order status
      await orderRepository.updateById(orderId, {
        status: ORDER_STATUS.CONFIRMED,
        paymentStatus: PAYMENT_STATUS.PAID,
      });

      // Generate policies
      await this._generatePolicies(payment.user, orderId);

      await auditLogService.log({
        user: payment.user,
        action: AUDIT_ACTIONS.STATUS_CHANGE,
        entityType: 'Payment',
        entityId: payment._id,
        newData: { status: 'SUCCESS', paymentStatus: 'PAID' },
      });

      logger.info(`Payment SUCCESS processed for order ${orderId}`);
    } else if (paymentStatus === 'FAILED' || paymentStatus === 'CANCELLED') {
      updateData.status = PAYMENT_TRANSACTION_STATUS.FAILED;

      await paymentRepository.updateById(payment._id, updateData);

      // Update order payment status
      await orderRepository.updateById(orderId, {
        paymentStatus: PAYMENT_STATUS.FAILED,
      });

      await auditLogService.log({
        user: payment.user,
        action: AUDIT_ACTIONS.STATUS_CHANGE,
        entityType: 'Payment',
        entityId: payment._id,
        newData: { status: 'FAILED', cfStatus: paymentStatus },
      });

      logger.info(`Payment FAILED/CANCELLED processed for order ${orderId}`);
    } else {
      // PENDING or other intermediate statuses
      await paymentRepository.updateById(payment._id, updateData);
      logger.info(`Payment status ${paymentStatus} stored for order ${orderId}`);
    }

    return paymentRepository.findByOrder(orderId);
  }

  /**
   * Generate policies for each order item after successful payment.
   * @private
   */
  async _generatePolicies(userId, orderId) {
    const orderItems = await orderItemRepository.findByOrder(orderId);

    for (const item of orderItems) {
      const planData = item.plan;
      const durationMonths = planData.duration || 12;
      const startDate = new Date();
      const endDate = new Date();
      endDate.setMonth(endDate.getMonth() + durationMonths);

      await policyRepository.create({
        user: userId,
        order: orderId,
        orderItem: item._id,
        plan: item.plan._id || item.plan,
        application: item.application._id || item.application,
        policyNumber: generatePolicyNumber(),
        startDate,
        endDate,
        coverageAmount: item.coverageAmount,
        premium: item.premium,
      });
    }

    logger.info(`Policies generated for order ${orderId}, items: ${orderItems.length}`);
  }

  /**
   * Get payment by ID.
   */
  async getById(id) {
    const payment = await paymentRepository.findById(id, {
      path: 'order',
      select: 'orderNumber totalAmount status paymentStatus',
    });
    if (!payment) {
      throw ApiError.notFound(messages.PAYMENT.NOT_FOUND);
    }
    return payment;
  }

  /**
   * Get payment for a specific order.
   */
  async getByOrder(orderId) {
    const payment = await paymentRepository.findByOrder(orderId);
    if (!payment) {
      throw ApiError.notFound(messages.PAYMENT.NOT_FOUND);
    }
    return payment;
  }
}

module.exports = new PaymentService();
