const Joi = require('joi');
const { APPLICATION_STATUS } = require('../constants');

const fieldValueSchema = Joi.object({
  productField: Joi.string().hex().length(24).required(),
  fieldName: Joi.string().trim().required(),
  fieldValue: Joi.any().required(),
});

const createApplication = {
  body: Joi.object({
    planId: Joi.string().hex().length(24).required(),
    fieldValues: Joi.array().items(fieldValueSchema).optional(),
  }),
};

const updateApplicationStatus = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
  body: Joi.object({
    status: Joi.string()
      .valid(...Object.values(APPLICATION_STATUS))
      .required(),
    remarks: Joi.string().trim().max(2000).optional().allow(''),
  }),
};

const getApplication = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
};

module.exports = {
  createApplication,
  updateApplicationStatus,
  getApplication,
};
