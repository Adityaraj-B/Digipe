const Joi = require('joi');
const { CLAIM_STATUS, DOCUMENT_TYPES } = require('../constants');

const createClaim = {
  body: Joi.object({
    policyId: Joi.string().hex().length(24).required(),
    description: Joi.string().trim().max(5000).required(),
    reason: Joi.string().trim().max(2000).optional().allow(''),
    incidentDate: Joi.date().iso().optional(),
    claimAmount: Joi.number().min(0).required(),
    images: Joi.array().items(Joi.string().hex().length(24)).optional(),
    videos: Joi.array().items(Joi.string().hex().length(24)).optional(),
  }),
};

const updateClaimStatus = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
  body: Joi.object({
    status: Joi.string()
      .valid(...Object.values(CLAIM_STATUS))
      .required(),
    remarks: Joi.string().trim().max(2000).optional().allow(''),
    settledAmount: Joi.number().min(0).optional(),
  }),
};

const addClaimDocument = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
  body: Joi.object({
    documentId: Joi.string().hex().length(24).required(),
    documentType: Joi.string()
      .valid(...Object.values(DOCUMENT_TYPES))
      .optional(),
  }),
};

const getClaim = {
  params: Joi.object({
    id: Joi.string().hex().length(24).required(),
  }),
};

module.exports = {
  createClaim,
  updateClaimStatus,
  addClaimDocument,
  getClaim,
};
