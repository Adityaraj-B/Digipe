const Joi = require('joi');

const getConsent = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
};

const recordUserConsent = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
};

module.exports = {
  getConsent,
  recordUserConsent,
};
