const Joi = require('joi');

const createOrder = {
  body: Joi.object({
    items: Joi.array()
      .items(
        Joi.object({
          planId: Joi.string().hex().length(24).required(),
          applicationId: Joi.string().hex().length(24).required(),
        })
      )
      .min(1)
      .required()
      .messages({
        'array.min': 'At least one item is required to create an order',
      }),
  }),
};

const getOrder = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
};

module.exports = {
  createOrder,
  getOrder,
};