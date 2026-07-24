const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');

/**
 * Validation middleware factory using Joi.
 * Validates req.body, req.query, or req.params based on the schema provided.
 *
 * @param {Object} schema - Joi schema object with optional body, query, params keys
 * @returns {Function} Express middleware
 */
const validate = (schema) => {
  return (req, res, next) => {
    const validationErrors = [];

    ['params', 'query', 'body'].forEach((key) => {
      if (schema[key]) {
        const { error, value } = schema[key].validate(req[key], {
          abortEarly: false,
          allowUnknown: key === 'query',
          stripUnknown: key !== 'query',
        });

        if (error) {
          const errors = error.details.map((detail) => ({
            field: detail.path.join('.'),
            message: detail.message.replace(/"/g, ''),
          }));
          validationErrors.push(...errors);
        } else {
          req[key] = value;
        }
      }
    });

    if (validationErrors.length > 0) {
      return next(ApiError.badRequest(messages.GENERAL.VALIDATION_ERROR, validationErrors));
    }

    next();
  };
};

module.exports = validate;
