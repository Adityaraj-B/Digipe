const Joi = require('joi');
const { PAYMENT_METHOD } = require('../constants');

const createPayment = {
  body: Joi.object({
    orderId: Joi.string().hex().length(24).required(),
    paymentMethod: Joi.string()
      .valid(...Object.values(PAYMENT_METHOD))
      .optional()
      .allow(null, ''),
  }),
};

const verifyPayment = {
  params: Joi.object({
    orderId: Joi.string().hex().length(24).required(),
  }),
};

const getPayment = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
};

const getPaymentByOrder = {
  params: Joi.object({
    orderId: Joi.string().hex().length(24).required(),
  }),
};

module.exports = {
  createPayment,
  verifyPayment,
  getPayment,
  getPaymentByOrder,
};
