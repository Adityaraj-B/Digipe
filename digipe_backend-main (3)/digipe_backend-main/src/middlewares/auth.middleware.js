const jwt = require('jsonwebtoken');
const env = require('../config/env');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const User = require('../models/user.model');

/**
 * JWT Authentication Middleware.
 * Extracts and verifies the Bearer token from the Authorization header.
 * Attaches the user object to req.user.
 */
const authenticate = async (req, res, next) => {
  try {
    let token = null;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      throw ApiError.unauthorized(messages.AUTH.TOKEN_MISSING);
    }

    let decoded;
    try {
      decoded = jwt.verify(token, env.jwt.secret);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        throw ApiError.unauthorized(messages.AUTH.TOKEN_EXPIRED);
      }
      throw ApiError.unauthorized(messages.AUTH.INVALID_TOKEN);
    }

    const user = await User.findById(decoded.id);

    if (!user) {
      throw ApiError.unauthorized(messages.AUTH.UNAUTHORIZED);
    }

    if (!user.isActive) {
      throw ApiError.forbidden(messages.AUTH.ACCOUNT_DEACTIVATED);
    }

    req.user = user;
    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Optional authentication — attaches user if token is present, but doesn't fail.
 */
const optionalAuth = async (req, res, next) => {
  try {
    let token = null;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (token) {
      try {
        const decoded = jwt.verify(token, env.jwt.secret);
        const user = await User.findById(decoded.id);
        if (user && user.isActive) {
          req.user = user;
        }
      } catch (err) {
        // Token invalid or expired — just proceed without user
      }
    }

    next();
  } catch (error) {
    next(error);
  }
};

module.exports = { authenticate, optionalAuth };
