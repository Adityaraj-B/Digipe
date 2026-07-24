const Order = require('../models/order.model');
const Policy = require('../models/policy.model');
const OrderItem = require('../models/orderItem.model');
const Payment = require('../models/payment.model');
const InsuranceApplication = require('../models/insuranceApplication.model');
const ApplicationFieldValue = require('../models/applicationFieldValue.model');
const Document = require('../models/document.model');
const Consent = require('../models/consent.model');
const mongoose = require('mongoose');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const auditLogService = require('./auditLog.service');
const { ORDER_STATUS, POLICY_STATUS, CLAIM_STATUS, AUDIT_ACTIONS } = require('../constants');

/**
 * Maps internal database statuses (Order + Policy + Claim) to a single
 * frontend-friendly display status.
 *
 * Frontend expects: Active | Claim Raised | Claim Approved | Expired | Cancelled
 * Database stores:  Order.status (PENDING/CONFIRMED/CANCELLED)
 *                   Policy.status (ACTIVE/EXPIRED/CANCELLED/CLAIMED)
 *                   Claim.status (SUBMITTED/UNDER_REVIEW/APPROVED/REJECTED/SETTLED)
 */
function computeDisplayStatus(orderStatus, policyStatus, claimStatus) {
  // Order-level cancellation takes precedence
  if (orderStatus === ORDER_STATUS.CANCELLED) return 'Cancelled';
  // Order not yet confirmed
  if (orderStatus === ORDER_STATUS.PENDING) return 'Pending';

  // From here: order is CONFIRMED — derive from Policy and Claim
  if (policyStatus === POLICY_STATUS.CANCELLED) return 'Cancelled';
  if (policyStatus === POLICY_STATUS.EXPIRED) return 'Expired';

  // Claim states
  if (claimStatus === CLAIM_STATUS.APPROVED || claimStatus === CLAIM_STATUS.SETTLED) return 'Claim Approved';
  if (claimStatus === CLAIM_STATUS.SUBMITTED || claimStatus === CLAIM_STATUS.UNDER_REVIEW) return 'Claim Raised';

  // Default: active confirmed policy
  if (policyStatus === POLICY_STATUS.ACTIVE) return 'Active';

  return 'Active'; // fallback for CONFIRMED orders with no policy yet
}

/**
 * Reverse-maps a frontend display status filter into database query conditions.
 */
function getStatusFilter(displayStatus) {
  switch (displayStatus) {
    case 'Active':
      return { status: ORDER_STATUS.CONFIRMED, 'policyInfo.status': POLICY_STATUS.ACTIVE };
    case 'Cancelled':
      return {
        $or: [
          { status: ORDER_STATUS.CANCELLED },
          { 'policyInfo.status': POLICY_STATUS.CANCELLED }
        ]
      };
    case 'Expired':
      return { 'policyInfo.status': POLICY_STATUS.EXPIRED };
    case 'Claim Raised':
      return {
        'claimInfo.status': { $in: [CLAIM_STATUS.SUBMITTED, CLAIM_STATUS.UNDER_REVIEW] }
      };
    case 'Claim Approved':
      return {
        'claimInfo.status': { $in: [CLAIM_STATUS.APPROVED, CLAIM_STATUS.SETTLED] }
      };
    case 'Pending':
      return { status: ORDER_STATUS.PENDING };
    default:
      return {};
  }
}

class AdminOrderService {
  /**
   * Get all orders for admin with pagination, search, and filters.
   *
   * Uses aggregation to join Order → User, OrderItem → InsurancePlan → InsuranceProduct,
   * Policy, and Claim to build the response the frontend expects.
   */
  async getAllOrders(query) {
    const {
      page = 1,
      limit = 10,
      search = '',
      status = 'All',
      product = 'All',
    } = query;

    const pageNumber = parseInt(page, 10);
    const limitNumber = parseInt(limit, 10);
    const skip = (pageNumber - 1) * limitNumber;

    const pipeline = [];

    // Stage 1: filter soft-deleted orders early
    pipeline.push({ $match: { isDeleted: false } });

    // Stage 2: Lookup user for email search/display
    pipeline.push({
      $lookup: {
        from: 'users',
        localField: 'user',
        foreignField: '_id',
        as: 'userInfo'
      }
    });
    pipeline.push({ $unwind: { path: '$userInfo', preserveNullAndEmptyArrays: true } });

    // Stage 3: Lookup order items
    pipeline.push({
      $lookup: {
        from: 'orderitems',
        localField: '_id',
        foreignField: 'order',
        as: 'items'
      }
    });

    // Stage 4: Lookup plans (collection name = insuranceplans from model InsurancePlan)
    pipeline.push({
      $lookup: {
        from: 'insuranceplans',
        localField: 'items.plan',
        foreignField: '_id',
        as: 'plansInfo'
      }
    });

    // Stage 5: Lookup products (collection name = insuranceproducts from model InsuranceProduct)
    pipeline.push({
      $lookup: {
        from: 'insuranceproducts',
        localField: 'plansInfo.product',
        foreignField: '_id',
        as: 'productsInfo'
      }
    });

    // Stage 6: Lookup policies for this order (to derive display status)
    pipeline.push({
      $lookup: {
        from: 'policies',
        localField: '_id',
        foreignField: 'order',
        as: 'policyInfo'
      }
    });

    // Stage 7: Lookup claims through policies
    pipeline.push({
      $lookup: {
        from: 'claims',
        localField: 'policyInfo._id',
        foreignField: 'policy',
        as: 'claimInfo'
      }
    });

    // Stage 8: Apply search filter
    if (search) {
      const searchConditions = [
        { 'userInfo.email': { $regex: search, $options: 'i' } },
        { orderNumber: { $regex: search, $options: 'i' } },
      ];
      // Only add _id match if the search string is a valid ObjectId
      if (mongoose.Types.ObjectId.isValid(search)) {
        searchConditions.push({ _id: new mongoose.Types.ObjectId(search) });
      }
      pipeline.push({ $match: { $or: searchConditions } });
    }

    // Stage 9: Apply product filter
    if (product && product !== 'All') {
      pipeline.push({
        $match: { 'productsInfo.name': { $regex: `^${product}$`, $options: 'i' } }
      });
    }

    // Stage 10: Apply status filter (maps frontend display status to DB conditions)
    if (status && status !== 'All') {
      const statusFilter = getStatusFilter(status);
      if (Object.keys(statusFilter).length > 0) {
        pipeline.push({ $match: statusFilter });
      }
    }

    // Stage 11: Sort by newest first
    pipeline.push({ $sort: { createdAt: -1 } });

    // Stage 12: Facet for pagination + data projection
    pipeline.push({
      $facet: {
        metadata: [{ $count: 'total' }],
        data: [
          { $skip: skip },
          { $limit: limitNumber },
          {
            $project: {
              _id: 1,
              orderNumber: 1,
              email: '$userInfo.email',
              amount: '$totalAmount',
              status: 1,
              paymentStatus: 1,
              createdAt: 1,
              date: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
              years: {
                $let: {
                  vars: {
                    durationMonths: { $ifNull: [{ $max: '$plansInfo.duration' }, 12] }
                  },
                  in: {
                    $toString: { $ceil: { $divide: ['$$durationMonths', 12] } }
                  }
                }
              },
              product: { $ifNull: [{ $arrayElemAt: ['$productsInfo.name', 0] }, 'N/A'] },
              // Pass raw statuses so we can compute display status in JS
              policyStatus: { $ifNull: [{ $arrayElemAt: ['$policyInfo.status', 0] }, null] },
              claimStatus: { $ifNull: [{ $arrayElemAt: ['$claimInfo.status', 0] }, null] },
            }
          }
        ]
      }
    });

    const result = await Order.aggregate(pipeline).exec();

    const rawData = result[0].data || [];
    const total = result[0].metadata[0]?.total || 0;

    // Map each order to compute the unified frontend display status
    const orders = rawData.map(order => ({
      id: order._id,
      orderNumber: order.orderNumber,
      email: order.email,
      amount: order.amount,
      status: computeDisplayStatus(order.status, order.policyStatus, order.claimStatus),
      createdAt: order.createdAt,
      date: order.date,
      years: order.years,
      product: order.product,
    }));

    return {
      orders,
      pagination: {
        total,
        page: pageNumber,
        limit: limitNumber,
        totalPages: Math.ceil(total / limitNumber)
      }
    };
  }

  /**
   * Update order status with transaction support.
   *
   * PATCH whitelist matches Order.status enum: PENDING, CONFIRMED, CANCELLED.
   * If status is set to CANCELLED, cascade-cancel all associated policies
   * within the same transaction.
   */
  async updateOrderStatus(orderId, newStatus) {
    // Validate against the actual Order model enum
    if (!Object.values(ORDER_STATUS).includes(newStatus)) {
      throw ApiError.badRequest(
        `Invalid status '${newStatus}'. Allowed: ${Object.values(ORDER_STATUS).join(', ')}`
      );
    }

    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      const order = await Order.findById(orderId).session(session);
      if (!order) {
        throw ApiError.notFound(messages.ORDER.NOT_FOUND);
      }

      order.status = newStatus;
      await order.save({ session });

      // Cascade: if order is cancelled, cancel all associated policies
      if (newStatus === ORDER_STATUS.CANCELLED) {
        await Policy.updateMany(
          { order: orderId, isDeleted: false },
          { $set: { status: POLICY_STATUS.CANCELLED } },
          { session }
        );
      }

      await session.commitTransaction();
      session.endSession();

      return order;
    } catch (error) {
      await session.abortTransaction();
      session.endSession();
      throw error;
    }
  }

  /**
   * Get detailed order view for admin.
   * Returns complete order data including customer, plan, verification documents,
   * application field values, and consent information.
   */
  async getOrderDetail(orderId) {
    if (!mongoose.Types.ObjectId.isValid(orderId)) {
      throw ApiError.badRequest('Invalid order ID format');
    }

    const order = await Order.findById(orderId)
      .populate('user', 'name mobileNumber email profileImage')
      .populate('application');

    if (!order) {
      throw ApiError.notFound(messages.ORDER.NOT_FOUND);
    }

    // Get order items with plan and product details
    const orderItems = await OrderItem.find({ order: orderId })
      .populate({
        path: 'plan',
        select: 'name coverageAmount premium premiumFrequency duration features benefits exclusions',
        populate: { path: 'product', select: 'name slug image description' },
      })
      .populate('application', 'applicationNumber status remarks reviewedAt');

    // Get application field values (customer-filled form data)
    const applicationIds = orderItems.map((item) => item.application?._id || item.application).filter(Boolean);
    const fieldValues = await ApplicationFieldValue.find({
      application: { $in: applicationIds },
      isDeleted: false,
    }).populate('productField', 'fieldName fieldLabel fieldType');

    // Get verification documents (linked to applications)
    const verificationDocs = await Document.find({
      application: { $in: applicationIds },
      isDeleted: false,
    }).select('originalName url mimeType size fileType createdAt');

    // Get all documents uploaded by the user (for broader coverage)
    const userDocs = await Document.find({
      user: order.user._id,
      isDeleted: false,
    }).select('originalName url mimeType size fileType createdAt');

    // Separate into images and videos
    const images = userDocs.filter((d) => d.fileType === 'IMAGE').map((d) => ({
      fileUrl: d.url,
      fileType: d.fileType,
      uploadedAt: d.createdAt,
      originalName: d.originalName,
    }));
    const videos = userDocs.filter((d) => d.fileType === 'VIDEO').map((d) => ({
      fileUrl: d.url,
      fileType: d.fileType,
      uploadedAt: d.createdAt,
      originalName: d.originalName,
    }));

    // Get policies for this order
    const policies = await Policy.find({ order: orderId, isDeleted: false })
      .select('policyNumber startDate endDate coverageAmount premium status');

    // Get consent info
    const consent = applicationIds.length > 0
      ? await Consent.findOne({ application: { $in: applicationIds } })
          .populate('adminUser', 'name mobileNumber')
      : null;

    // Compute display status
    const policyStatus = policies.length > 0 ? policies[0].status : null;
    const displayStatus = computeDisplayStatus(order.status, policyStatus, null);

    return {
      order: {
        id: order._id,
        orderNumber: order.orderNumber,
        subtotal: order.subtotal,
        discountPercentage: order.discountPercentage,
        discountAmount: order.discountAmount,
        gstPercentage: order.gstPercentage,
        taxAmount: order.taxAmount,
        totalAmount: order.totalAmount,
        status: order.status,
        displayStatus,
        paymentStatus: order.paymentStatus,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
      },
      customer: order.user ? {
        id: order.user._id,
        name: order.user.name,
        mobileNumber: order.user.mobileNumber,
        email: order.user.email,
        profileImage: order.user.profileImage,
      } : null,
      planDetails: orderItems.map((item) => ({
        planName: item.plan?.name,
        productName: item.plan?.product?.name,
        coverageAmount: item.coverageAmount,
        premium: item.premium,
        duration: item.plan?.duration,
        premiumFrequency: item.plan?.premiumFrequency,
        features: item.plan?.features,
        benefits: item.plan?.benefits,
        exclusions: item.plan?.exclusions,
        applicationNumber: item.application?.applicationNumber,
        applicationStatus: item.application?.status,
      })),
      verificationDetails: {
        fieldValues: fieldValues.map((fv) => ({
          fieldKey: fv.fieldName,
          fieldLabel: fv.productField?.fieldLabel || fv.fieldName,
          fieldName: fv.productField?.fieldLabel || fv.fieldName,
          fieldValue: fv.fieldValue,
          fieldType: fv.productField?.fieldType,
        })),
        documents: verificationDocs.map((d) => ({
          fileUrl: d.url,
          fileType: d.fileType,
          uploadedAt: d.createdAt,
          originalName: d.originalName,
        })),
      },
      uploadedImages: images,
      uploadedVideos: videos,
      policies,
      consent: consent ? {
        userConsent: consent.userConsent,
        adminApproval: consent.adminApproval,
        consentTimestamp: consent.consentTimestamp,
        approvalTimestamp: consent.approvalTimestamp,
        approvedBy: consent.adminUser?.name,
      } : null,
      currentStatus: displayStatus,
    };
  }

  /**
   * Soft-delete an order (admin action).
   *
   * Only PENDING or CANCELLED orders can be deleted.
   * CONFIRMED orders with active policies are protected.
   *
   * Cascade:
   *   - Soft-deletes the Order record
   *   - Hard-deletes associated Payment record (pending/failed only)
   *   - Logs via audit service
   *
   * After deletion the Order model's pre(/^find/) middleware
   * automatically excludes it from all find queries, so:
   *   - Admin listing ignores it
   *   - User listing ignores it
   *   - Payment & order creation validations ignore it
   */
  async deleteOrder(orderId) {
    if (!mongoose.Types.ObjectId.isValid(orderId)) {
      throw ApiError.badRequest('Invalid order ID format');
    }

    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      // Use includeDeleted: false (default) — only find active orders
      const order = await Order.findById(orderId).session(session);
      if (!order) {
        throw ApiError.notFound(messages.ORDER.NOT_FOUND);
      }

      // Guard: prevent deleting confirmed orders with potential active policies
      if (order.status === ORDER_STATUS.CONFIRMED) {
        throw ApiError.badRequest(
          'Cannot delete a confirmed order. Cancel it first if needed.'
        );
      }

      // 1. Soft-delete the order
      order.isDeleted = true;
      order.deletedAt = new Date();
      await order.save({ session });

      // 2. Hard-delete associated payment records (pending/failed — no successful transaction)
      await Payment.deleteMany({ order: orderId }, { session });

      await session.commitTransaction();
      session.endSession();

      // 3. Audit log (outside transaction — non-critical)
      await auditLogService.log({
        user: null, // admin action — no specific user context available here
        action: AUDIT_ACTIONS.DELETE,
        entityType: 'Order',
        entityId: orderId,
        previousData: {
          orderNumber: order.orderNumber,
          status: order.status,
          paymentStatus: order.paymentStatus,
          totalAmount: order.totalAmount,
        },
      });

      return { message: messages.ORDER.DELETED };
    } catch (error) {
      await session.abortTransaction();
      session.endSession();
      throw error;
    }
  }
}

module.exports = new AdminOrderService();
