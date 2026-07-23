const Joi = require('joi');
const { PREMIUM_FREQUENCY } = require('../constants');

const createPlan = {
  body: Joi.object({
    product: Joi.string().hex().length(24).required(),
    name: Joi.string().trim().max(200).required(),
    description: Joi.string().trim().max(3000).optional().allow(''),
    coverageAmount: Joi.number().min(0).required(),
    premium: Joi.number().min(0).required(),
    premiumFrequency: Joi.string()
      .valid(...Object.values(PREMIUM_FREQUENCY))
      .optional(),
    duration: Joi.number().integer().min(1).required()
      .messages({ 'number.min': 'Duration must be at least 1 month' }),
    features: Joi.array().items(Joi.string().trim()).optional(),
    benefits: Joi.array().items(Joi.string().trim()).optional(),
    exclusions: Joi.array().items(Joi.string().trim()).optional(),
    isActive: Joi.boolean().optional(),
    sortOrder: Joi.number().integer().min(0).optional(),
  }),
};

const updatePlan = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
  body: Joi.object({
    product: Joi.string().hex().length(24).optional(),
    name: Joi.string().trim().max(200).optional(),
    description: Joi.string().trim().max(3000).optional().allow(''),
    coverageAmount: Joi.number().min(0).optional(),
    premium: Joi.number().min(0).optional(),
    premiumFrequency: Joi.string()
      .valid(...Object.values(PREMIUM_FREQUENCY))
      .optional(),
    duration: Joi.number().integer().min(1).optional(),
    features: Joi.array().items(Joi.string().trim()).optional(),
    benefits: Joi.array().items(Joi.string().trim()).optional(),
    exclusions: Joi.array().items(Joi.string().trim()).optional(),
    isActive: Joi.boolean().optional(),
    sortOrder: Joi.number().integer().min(0).optional(),
  }),
};

const getPlan = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
};

const getByProduct = {
  params: Joi.object({
    productId: Joi.string().hex().length(24).required(),
  }),
};

module.exports = {
  createPlan,
  updatePlan,
  getPlan,
  getByProduct,
};
