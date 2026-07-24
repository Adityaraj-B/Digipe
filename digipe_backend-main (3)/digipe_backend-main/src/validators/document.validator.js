const Joi = require('joi');

const getDocument = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
};

const deleteDocument = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
};

const uploadMultiple = {
  body: Joi.object({
    applicationId: Joi.string().hex().length(24).optional().allow('', null),
  }),
};

module.exports = {
  getDocument,
  deleteDocument,
  uploadMultiple,
};
