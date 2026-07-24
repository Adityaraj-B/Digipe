const productRepository = require('../repositories/product.repository');
const categoryRepository = require('../repositories/category.repository');
const auditLogService = require('./auditLog.service');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const { slugify } = require('../utils/helpers');
const { buildPaginationMeta } = require('../utils/pagination');
const { AUDIT_ACTIONS } = require('../constants');

class ProductService {
  async create(data, userId) {
    const category = await categoryRepository.findById(data.category);
    if (!category) {
      throw ApiError.notFound(messages.CATEGORY.NOT_FOUND);
    }

    const existing = await productRepository.findByName(data.name);
    if (existing) {
      throw ApiError.conflict(messages.PRODUCT.ALREADY_EXISTS);
    }

    data.slug = slugify(data.name);
    const slugExists = await productRepository.findBySlug(data.slug);
    if (slugExists) {
      data.slug = `${data.slug}-${Date.now()}`;
    }

    const product = await productRepository.create(data);

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.CREATE,
      entityType: 'InsuranceProduct',
      entityId: product._id,
      newData: product.toObject(),
    });

    return product;
  }

  async getAll(filter, options) {
    const { docs, totalDocs } = await productRepository.findWithPagination(
      { ...filter, isActive: true },
      {
        ...options,
        sort: options.sort || { sortOrder: 1, createdAt: -1 },
        populate: { path: 'category', select: 'name slug icon' },
      }
    );
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { products: docs, meta };
  }

  async getById(id) {
    const product = await productRepository.findByIdWithDetails(id);
    if (!product) {
      throw ApiError.notFound(messages.PRODUCT.NOT_FOUND);
    }
    return product;
  }

  async getByCategory(categoryId, options) {
    const category = await categoryRepository.findById(categoryId);
    if (!category) {
      throw ApiError.notFound(messages.CATEGORY.NOT_FOUND);
    }

    const { docs, totalDocs } = await productRepository.findWithPagination(
      { category: categoryId, isActive: true },
      {
        ...options,
        sort: options.sort || { sortOrder: 1 },
        populate: { path: 'category', select: 'name slug icon' },
      }
    );
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { products: docs, meta };
  }

  async update(id, data, userId) {
    const product = await productRepository.findById(id);
    if (!product) {
      throw ApiError.notFound(messages.PRODUCT.NOT_FOUND);
    }

    if (data.category) {
      const category = await categoryRepository.findById(data.category);
      if (!category) {
        throw ApiError.notFound(messages.CATEGORY.NOT_FOUND);
      }
    }

    if (data.name && data.name !== product.name) {
      const existing = await productRepository.findByName(data.name);
      if (existing && existing._id.toString() !== id) {
        throw ApiError.conflict(messages.PRODUCT.ALREADY_EXISTS);
      }
      data.slug = slugify(data.name);
    }

    const previousData = product.toObject();
    const updated = await productRepository.updateById(id, data);

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.UPDATE,
      entityType: 'InsuranceProduct',
      entityId: id,
      previousData,
      newData: updated.toObject(),
    });

    return updated;
  }

  async delete(id, userId) {
    const product = await productRepository.findById(id);
    if (!product) {
      throw ApiError.notFound(messages.PRODUCT.NOT_FOUND);
    }

    const previousData = product.toObject();
    await productRepository.softDelete(id);

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.DELETE,
      entityType: 'InsuranceProduct',
      entityId: id,
      previousData,
    });

    return { message: messages.PRODUCT.DELETED };
  }
}

module.exports = new ProductService();
