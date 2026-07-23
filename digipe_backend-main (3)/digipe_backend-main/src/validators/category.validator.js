const Joi = require('joi');

const createCategory = {
  body: Joi.object({
    name: Joi.string().trim().max(150).required(),
    description: Joi.string().trim().max(1000).optional().allow(''),
    icon: Joi.string().trim().optional().allow(''),
    image: Joi.string().uri().optional().allow(''),
    isActive: Joi.boolean().optional(),
    sortOrder: Joi.number().integer().min(0).optional(),
  }),
};

const updateCategory = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
  body: Joi.object({
    name: Joi.string().trim().max(150).optional(),
    description: Joi.string().trim().max(1000).optional().allow(''),
    icon: Joi.string().trim().optional().allow(''),
    image: Joi.string().uri().optional().allow(''),
    isActive: Joi.boolean().optional(),
    sortOrder: Joi.number().integer().min(0).optional(),
  }),
};

const getCategory = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
};

module.exports = {
  createCategory,
  updateCategory,
  getCategory,
};
