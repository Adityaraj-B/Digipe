const policyRepository = require('../repositories/policy.repository');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const { buildPaginationMeta } = require('../utils/pagination');

class PolicyService {
  /**
   * Get customer's policies with pagination.
   */
  async getMyPolicies(userId, options) {
    const { docs, totalDocs } = await policyRepository.findByUser(userId, options);
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { policies: docs, meta };
  }

  /**
   * Get all policies (admin) with pagination.
   */
  async getAll(filter, options) {
    const { docs, totalDocs } = await policyRepository.findWithPagination(filter, {
      ...options,
      populate: [
        { path: 'user', select: 'name mobileNumber email' },
        { path: 'plan', select: 'name coverageAmount premium', populate: { path: 'product', select: 'name slug' } },
        { path: 'order', select: 'orderNumber' },
      ],
    });
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { policies: docs, meta };
  }

  /**
   * Get a single policy by ID with full details.
   */
  async getById(id) {
    const policy = await policyRepository.findByIdWithDetails(id);
    if (!policy) {
      throw ApiError.notFound(messages.POLICY.NOT_FOUND);
    }
    return policy;
  }
}

module.exports = new PolicyService();
