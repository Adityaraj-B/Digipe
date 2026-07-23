const Joi = require('joi');

const createProduct = {
  body: Joi.object({
    category: Joi.string().hex().length(24).required(),
    name: Joi.string().trim().max(200).required(),
    description: Joi.string().trim().max(5000).optional().allow(''),
    shortDescription: Joi.string().trim().max(500).optional().allow(''),
    image: Joi.string().uri().optional().allow(''),
    features: Joi.array().items(Joi.string().trim()).optional(),
    isActive: Joi.boolean().optional(),
    sortOrder: Joi.number().integer().min(0).optional(),
  }),
};

const updateProduct = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
  body: Joi.object({
    category: Joi.string().hex().length(24).optional(),
    name: Joi.string().trim().max(200).optional(),
    description: Joi.string().trim().max(5000).optional().allow(''),
    shortDescription: Joi.string().trim().max(500).optional().allow(''),
    image: Joi.string().uri().optional().allow(''),
    features: Joi.array().items(Joi.string().trim()).optional(),
    isActive: Joi.boolean().optional(),
    sortOrder: Joi.number().integer().min(0).optional(),
  }),
};

const getProduct = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
};

const getByCategory = {
  params: Joi.object({
    categoryId: Joi.string().hex().length(24).required(),
  }),
};

module.exports = {
  createProduct,
  updateProduct,
  getProduct,
  getByCategory,
};
