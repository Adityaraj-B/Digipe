const mongoose = require('mongoose');
const InsuranceProduct = require('../models/insuranceProduct.model');
const InsurancePlan = require('../models/insurancePlan.model');
const Policy = require('../models/policy.model');
const OrderItem = require('../models/orderItem.model');
const Order = require('../models/order.model');
const Claim = require('../models/claim.model');
const Payment = require('../models/payment.model');
const User = require('../models/user.model');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');

class AdminService {
  /**
   * Get admin dashboard data. Scoped to a specific product if productId is supplied,
   * otherwise aggregated globally.
   * @param {string} [productId] - Optional Product ID
   * @returns {Promise<Object>} Dashboard metrics, recent purchases, and claims queue.
   */
  async getDashboardData(productId) {
    let planIds = [];
    let isProductScoped = false;
    let prodIdObj = null;

    if (productId) {
      if (!mongoose.Types.ObjectId.isValid(productId)) {
        throw ApiError.badRequest('Invalid Product ID format');
      }
      prodIdObj = new mongoose.Types.ObjectId(productId);

      // Verify product exists
      const product = await InsuranceProduct.findOne({ _id: prodIdObj, isDeleted: false });
      if (!product) {
        throw ApiError.notFound(messages.PRODUCT?.NOT_FOUND || 'Insurance Product not found');
      }

      // Get plans for this product
      const plans = await InsurancePlan.find({ product: prodIdObj, isDeleted: false }).select('_id');
      planIds = plans.map((p) => p._id);
      isProductScoped = true;
    }

    // Common query parameters
    let totalSales = 0;
    let totalOrders = 0;
    let totalClaims = 0;
    let totalUsers = 0;
    let recentPurchases = [];
    let claimsQueue = [];

    if (isProductScoped && planIds.length === 0) {
      // Scoped view but product has no plans — return empty statistics
      return {
        metrics: { totalSales, totalOrders, totalClaims, totalUsers },
        recentPurchases,
        claimsQueue,
      };
    }

    // 1. Total Sales
    if (isProductScoped) {
      const salesResult = await Payment.aggregate([
        { $match: { status: 'SUCCESS', isDeleted: false } },
        {
          $lookup: {
            from: 'orderitems',
            localField: 'order',
            foreignField: 'order',
            as: 'items',
          },
        },
        { $unwind: '$items' },
        { $match: { 'items.plan': { $in: planIds } } },
        {
          $group: {
            _id: null,
            totalSales: { $sum: '$items.premium' },
          },
        },
      ]);
      totalSales = salesResult.length > 0 ? salesResult[0].totalSales : 0;
    } else {
      const salesResult = await Payment.aggregate([
        { $match: { status: 'SUCCESS', isDeleted: false } },
        {
          $group: {
            _id: null,
            totalSales: { $sum: '$amount' },
          },
        },
      ]);
      totalSales = salesResult.length > 0 ? salesResult[0].totalSales : 0;
    }

    // 2. Total Orders
    if (isProductScoped) {
      const totalOrdersResult = await OrderItem.aggregate([
        { $match: { plan: { $in: planIds } } },
        {
          $lookup: {
            from: 'orders',
            localField: 'order',
            foreignField: '_id',
            as: 'orderInfo',
          },
        },
        { $unwind: '$orderInfo' },
        {
          $match: {
            'orderInfo.isDeleted': false,
            'orderInfo.status': { $ne: 'CANCELLED' },
          },
        },
        {
          $group: {
            _id: '$order',
          },
        },
        {
          $count: 'count',
        },
      ]);
      totalOrders = totalOrdersResult.length > 0 ? totalOrdersResult[0].count : 0;
    } else {
      totalOrders = await Order.countDocuments({
        status: { $ne: 'CANCELLED' },
        isDeleted: false,
      });
    }

    // 3. Total Claims
    if (isProductScoped) {
      const totalClaimsResult = await Claim.aggregate([
        { $match: { isDeleted: false } },
        {
          $lookup: {
            from: 'policies',
            localField: 'policy',
            foreignField: '_id',
            as: 'policyInfo',
          },
        },
        { $unwind: '$policyInfo' },
        {
          $match: {
            'policyInfo.plan': { $in: planIds },
            'policyInfo.isDeleted': false,
          },
        },
        {
          $count: 'count',
        },
      ]);
      totalClaims = totalClaimsResult.length > 0 ? totalClaimsResult[0].count : 0;
    } else {
      totalClaims = await Claim.countDocuments({ isDeleted: false });
    }

    // 4. Total Users
    if (isProductScoped) {
      const uniqueUsers = await Policy.distinct('user', {
        plan: { $in: planIds },
        isDeleted: false,
      });
      totalUsers = uniqueUsers.length;
    } else {
      totalUsers = await User.countDocuments({
        role: 'CUSTOMER',
        isActive: true,
        isDeleted: { $ne: true },
      });
    }

    // 5. Recent Purchases (5 most recent policies)
    const policyQuery = isProductScoped ? { plan: { $in: planIds }, isDeleted: false } : { isDeleted: false };
    const recentPolicies = await Policy.find(policyQuery)
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('user', 'name email')
      .populate({
        path: 'plan',
        select: 'name duration',
        populate: { path: 'product', select: 'name' },
      });

    recentPurchases = recentPolicies.map((policy) => ({
      id: policy._id,
      policyNumber: policy.policyNumber,
      productName: policy.plan?.product?.name || 'N/A',
      email: policy.user?.email || 'N/A',
      amount: policy.premium,
      years: policy.plan?.duration ? Math.round(policy.plan.duration / 12) : 1,
      status: policy.status,
      date: policy.createdAt,
    }));

    // 6. Claims Action Queue
    const matchClaimStage = {
      status: { $in: ['SUBMITTED', 'UNDER_REVIEW'] },
      isDeleted: false,
    };

    const claimsPipeline = [
      { $match: matchClaimStage },
      {
        $lookup: {
          from: 'policies',
          localField: 'policy',
          foreignField: '_id',
          as: 'policyInfo',
        },
      },
      { $unwind: '$policyInfo' },
    ];

    if (isProductScoped) {
      claimsPipeline.push({
        $match: {
          'policyInfo.plan': { $in: planIds },
          'policyInfo.isDeleted': false,
        },
      });
    } else {
      claimsPipeline.push({
        $match: {
          'policyInfo.isDeleted': false,
        },
      });
    }

    claimsPipeline.push(
      {
        $lookup: {
          from: 'insuranceplans',
          localField: 'policyInfo.plan',
          foreignField: '_id',
          as: 'planInfo',
        },
      },
      { $unwind: '$planInfo' },
      {
        $lookup: {
          from: 'insuranceproducts',
          localField: 'planInfo.product',
          foreignField: '_id',
          as: 'productInfo',
        },
      },
      { $unwind: '$productInfo' },
      {
        $lookup: {
          from: 'users',
          localField: 'user',
          foreignField: '_id',
          as: 'userInfo',
        },
      },
      { $unwind: '$userInfo' },
      {
        $project: {
          _id: 0,
          id: '$_id',
          claimNumber: 1,
          policyNumber: '$policyInfo.policyNumber',
          productName: '$productInfo.name',
          email: '$userInfo.email',
          amount: '$policyInfo.premium',
          years: { $round: [{ $divide: ['$planInfo.duration', 12] }, 0] },
          date: '$createdAt',
          status: { $literal: 'Claim Raised' },
          claimAmount: '$claimAmount',
          description: '$description',
        },
      },
      { $sort: { date: -1 } }
    );

    claimsQueue = await Claim.aggregate(claimsPipeline);

    return {
      metrics: {
        totalSales,
        totalOrders,
        totalClaims,
        totalUsers,
      },
      recentPurchases,
      claimsQueue,
    };
  }
}

module.exports = new AdminService();
