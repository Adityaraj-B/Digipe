const categoryRepository = require('../repositories/category.repository');
const auditLogService = require('./auditLog.service');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const { slugify } = require('../utils/helpers');
const { buildPaginationMeta } = require('../utils/pagination');
const { AUDIT_ACTIONS } = require('../constants');

class CategoryService {
  async create(data, userId) {
    const existing = await categoryRepository.findByName(data.name);
    if (existing) {
      throw ApiError.conflict(messages.CATEGORY.ALREADY_EXISTS);
    }

    data.slug = slugify(data.name);

    // Ensure unique slug
    const slugExists = await categoryRepository.findBySlug(data.slug);
    if (slugExists) {
      data.slug = `${data.slug}-${Date.now()}`;
    }

    const category = await categoryRepository.create(data);

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.CREATE,
      entityType: 'InsuranceCategory',
      entityId: category._id,
      newData: category.toObject(),
    });

    return category;
  }

  async getAll(filter, options) {
    const { docs, totalDocs } = await categoryRepository.findWithPagination(
      { ...filter, isActive: true },
      { ...options, sort: options.sort || { sortOrder: 1, createdAt: -1 } }
    );
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { categories: docs, meta };
  }

  async getById(id) {
    const category = await categoryRepository.findById(id);
    if (!category) {
      throw ApiError.notFound(messages.CATEGORY.NOT_FOUND);
    }
    return category;
  }

  async update(id, data, userId) {
    const category = await categoryRepository.findById(id);
    if (!category) {
      throw ApiError.notFound(messages.CATEGORY.NOT_FOUND);
    }

    if (data.name && data.name !== category.name) {
      const existing = await categoryRepository.findByName(data.name);
      if (existing && existing._id.toString() !== id) {
        throw ApiError.conflict(messages.CATEGORY.ALREADY_EXISTS);
      }
      data.slug = slugify(data.name);
    }

    const previousData = category.toObject();
    const updated = await categoryRepository.updateById(id, data);

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.UPDATE,
      entityType: 'InsuranceCategory',
      entityId: id,
      previousData,
      newData: updated.toObject(),
    });

    return updated;
  }

  async delete(id, userId) {
    const category = await categoryRepository.findById(id);
    if (!category) {
      throw ApiError.notFound(messages.CATEGORY.NOT_FOUND);
    }

    const previousData = category.toObject();
    await categoryRepository.softDelete(id);

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.DELETE,
      entityType: 'InsuranceCategory',
      entityId: id,
      previousData,
    });

    return { message: messages.CATEGORY.DELETED };
  }
}

module.exports = new CategoryService();
