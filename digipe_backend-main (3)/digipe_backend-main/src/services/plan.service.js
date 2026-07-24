const planRepository = require('../repositories/plan.repository');
const productRepository = require('../repositories/product.repository');
const auditLogService = require('./auditLog.service');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const { buildPaginationMeta } = require('../utils/pagination');
const { AUDIT_ACTIONS } = require('../constants');

class PlanService {
  async create(data, userId) {
    const product = await productRepository.findById(data.product);
    if (!product) {
      throw ApiError.notFound(messages.PRODUCT.NOT_FOUND);
    }

    const plan = await planRepository.create(data);

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.CREATE,
      entityType: 'InsurancePlan',
      entityId: plan._id,
      newData: plan.toObject(),
    });

    return plan;
  }

  async getAll(filter, options) {
    const { docs, totalDocs } = await planRepository.findWithPagination(
      { ...filter, isActive: true },
      {
        ...options,
        populate: { path: 'product', select: 'name slug category' },
      }
    );
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { plans: docs, meta };
  }

  async getById(id) {
    const plan = await planRepository.findByIdWithProduct(id);
    if (!plan) {
      throw ApiError.notFound(messages.PLAN.NOT_FOUND);
    }
    return plan;
  }

  async getByProduct(productId, options) {
    const product = await productRepository.findById(productId);
    if (!product) {
      throw ApiError.notFound(messages.PRODUCT.NOT_FOUND);
    }

    const { docs, totalDocs } = await planRepository.findWithPagination(
      { product: productId, isActive: true },
      { ...options, sort: options.sort || { sortOrder: 1, premium: 1 } }
    );
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { plans: docs, meta };
  }

  async update(id, data, userId) {
    const plan = await planRepository.findById(id);
    if (!plan) {
      throw ApiError.notFound(messages.PLAN.NOT_FOUND);
    }

    if (data.product) {
      const product = await productRepository.findById(data.product);
      if (!product) {
        throw ApiError.notFound(messages.PRODUCT.NOT_FOUND);
      }
    }

    const previousData = plan.toObject();
    const updated = await planRepository.updateById(id, data);

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.UPDATE,
      entityType: 'InsurancePlan',
      entityId: id,
      previousData,
      newData: updated.toObject(),
    });

    return updated;
  }

  async delete(id, userId) {
    const plan = await planRepository.findById(id);
    if (!plan) {
      throw ApiError.notFound(messages.PLAN.NOT_FOUND);
    }

    const previousData = plan.toObject();
    await planRepository.softDelete(id);

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.DELETE,
      entityType: 'InsurancePlan',
      entityId: id,
      previousData,
    });

    return { message: messages.PLAN.DELETED };
  }
}

module.exports = new PlanService();
