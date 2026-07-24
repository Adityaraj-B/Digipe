const productFieldRepository = require('../repositories/productField.repository');
const fieldOptionRepository = require('../repositories/fieldOption.repository');
const productRepository = require('../repositories/product.repository');
const auditLogService = require('./auditLog.service');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const { AUDIT_ACTIONS } = require('../constants');

class ProductFieldService {
  /**
   * Create a dynamic field for a product, including options for select/radio/checkbox.
   */
  async create(data, userId) {
    const product = await productRepository.findById(data.product);
    if (!product) {
      throw ApiError.notFound(messages.PRODUCT.NOT_FOUND);
    }

    const { options, ...fieldData } = data;

    const field = await productFieldRepository.create(fieldData);

    // Create field options if provided (for SELECT, RADIO, CHECKBOX)
    if (options && Array.isArray(options) && options.length > 0) {
      const optionDocs = options.map((opt, index) => ({
        productField: field._id,
        label: opt.label,
        value: opt.value,
        sortOrder: opt.sortOrder !== undefined ? opt.sortOrder : index,
      }));
      await fieldOptionRepository.createMany(optionDocs);
    }

    // Return field with populated options
    const populatedField = await productFieldRepository.findById(field._id, {
      path: 'options',
      match: { isActive: true },
      options: { sort: { sortOrder: 1 } },
    });

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.CREATE,
      entityType: 'ProductField',
      entityId: field._id,
      newData: populatedField.toObject(),
    });

    return populatedField;
  }

  /**
   * Get all dynamic fields for a product with their options.
   */
  async getByProduct(productId) {
    const product = await productRepository.findById(productId);
    if (!product) {
      throw ApiError.notFound(messages.PRODUCT.NOT_FOUND);
    }

    const fields = await productFieldRepository.findByProduct(productId);
    return fields;
  }

  /**
   * Update a dynamic field and optionally replace its options.
   */
  async update(id, data, userId) {
    const field = await productFieldRepository.findById(id);
    if (!field) {
      throw ApiError.notFound(messages.PRODUCT_FIELD.NOT_FOUND);
    }

    const { options, ...fieldData } = data;
    const previousData = field.toObject();

    const updated = await productFieldRepository.updateById(id, fieldData);

    // Replace options if provided
    if (options && Array.isArray(options)) {
      await fieldOptionRepository.deleteByField(id);

      if (options.length > 0) {
        const optionDocs = options.map((opt, index) => ({
          productField: id,
          label: opt.label,
          value: opt.value,
          sortOrder: opt.sortOrder !== undefined ? opt.sortOrder : index,
        }));
        await fieldOptionRepository.createMany(optionDocs);
      }
    }

    const populatedField = await productFieldRepository.findById(id, {
      path: 'options',
      match: { isActive: true },
      options: { sort: { sortOrder: 1 } },
    });

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.UPDATE,
      entityType: 'ProductField',
      entityId: id,
      previousData,
      newData: populatedField.toObject(),
    });

    return populatedField;
  }

  /**
   * Soft-delete a dynamic field and its options.
   */
  async delete(id, userId) {
    const field = await productFieldRepository.findById(id);
    if (!field) {
      throw ApiError.notFound(messages.PRODUCT_FIELD.NOT_FOUND);
    }

    const previousData = field.toObject();

    await fieldOptionRepository.deleteByField(id);
    await productFieldRepository.softDelete(id);

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.DELETE,
      entityType: 'ProductField',
      entityId: id,
      previousData,
    });

    return { message: messages.PRODUCT_FIELD.DELETED };
  }
}

module.exports = new ProductFieldService();
