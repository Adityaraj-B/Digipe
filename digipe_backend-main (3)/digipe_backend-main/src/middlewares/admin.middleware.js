const { ROLES } = require('../constants');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');

/**
 * Admin Authorization Middleware.
 * Must be used AFTER authenticate middleware.
 * Checks that the authenticated user has the ADMIN role.
 */
const authorizeAdmin = (req, res, next) => {
  if (!req.user) {
    return next(ApiError.unauthorized(messages.AUTH.UNAUTHORIZED));
  }

  if (req.user.role !== ROLES.ADMIN) {
    return next(ApiError.forbidden(messages.AUTH.FORBIDDEN));
  }

  next();
};

/**
 * Generic role-based authorization middleware.
 * @param  {...string} roles - Allowed roles
 * @returns {Function} Express middleware
 */
const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(ApiError.unauthorized(messages.AUTH.UNAUTHORIZED));
    }

    if (!roles.includes(req.user.role)) {
      return next(ApiError.forbidden(messages.AUTH.FORBIDDEN));
    }

    next();
  };
};

module.exports = { authorizeAdmin, authorizeRoles };
