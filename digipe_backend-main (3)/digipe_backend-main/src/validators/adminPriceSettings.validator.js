const Joi = require('joi');

const updatePromotionalDiscount = {
  body: Joi.object({
    percentage: Joi.number().min(0).max(100).required(),
    isActive: Joi.boolean().required(),
  }),
};

const updateTax = {
  body: Joi.object({
    gstPercentage: Joi.number().min(0).max(100).required(),
  }),
};

module.exports = {
  updatePromotionalDiscount,
  updateTax,
};
