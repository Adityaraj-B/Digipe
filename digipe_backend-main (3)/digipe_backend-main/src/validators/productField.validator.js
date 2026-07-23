const Joi = require('joi');
const { FIELD_TYPES } = require('../constants');

const optionSchema = Joi.object({
  label: Joi.string().trim().max(200).required(),
  value: Joi.string().trim().max(200).required(),
  sortOrder: Joi.number().integer().min(0).optional(),
});

const createProductField = {
  body: Joi.object({
    product: Joi.string().hex().length(24).required(),
    fieldName: Joi.string().trim().max(100).required(),
    fieldLabel: Joi.string().trim().max(200).required(),
    fieldType: Joi.string()
      .valid(...Object.values(FIELD_TYPES))
      .required(),
    placeholder: Joi.string().trim().max(200).optional().allow(''),
    isRequired: Joi.boolean().optional(),
    validationRules: Joi.object({
      min: Joi.number().optional().allow(null),
      max: Joi.number().optional().allow(null),
      minLength: Joi.number().integer().optional().allow(null),
      maxLength: Joi.number().integer().optional().allow(null),
      pattern: Joi.string().optional().allow('', null),
    }).optional(),
    options: Joi.array().items(optionSchema).optional(),
    sortOrder: Joi.number().integer().min(0).optional(),
    isActive: Joi.boolean().optional(),
  }),
};

const updateProductField = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
  body: Joi.object({
    fieldName: Joi.string().trim().max(100).optional(),
    fieldLabel: Joi.string().trim().max(200).optional(),
    fieldType: Joi.string()
      .valid(...Object.values(FIELD_TYPES))
      .optional(),
    placeholder: Joi.string().trim().max(200).optional().allow(''),
    isRequired: Joi.boolean().optional(),
    validationRules: Joi.object({
      min: Joi.number().optional().allow(null),
      max: Joi.number().optional().allow(null),
      minLength: Joi.number().integer().optional().allow(null),
      maxLength: Joi.number().integer().optional().allow(null),
      pattern: Joi.string().optional().allow('', null),
    }).optional(),
    options: Joi.array().items(optionSchema).optional(),
    sortOrder: Joi.number().integer().min(0).optional(),
    isActive: Joi.boolean().optional(),
  }),
};

const getByProduct = {
  params: Joi.object({
    productId: Joi.string().hex().length(24).required(),
  }),
};

module.exports = {
  createProductField,
  updateProductField,
  getByProduct,
};
