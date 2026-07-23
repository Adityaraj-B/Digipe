const logger = require('../config/logger');
const ApiError = require('../utils/apiError');

/**
 * Global error handling middleware.
 * Handles operational errors (ApiError), Mongoose errors, and unexpected errors.
 */
// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  console.log(`[TRACE][errorHandler] ENTER — url=${req.originalUrl}, method=${req.method}`);
  console.log(`[TRACE][errorHandler] Error: name=${err.name}, message=${err.message}, statusCode=${err.statusCode}, isApiError=${err instanceof ApiError}`);
  let error = err;

  // Mongoose bad ObjectId (CastError)
  if (err.name === 'CastError') {
    const message = `Invalid ${err.path}: ${err.value}`;
    error = ApiError.badRequest(message);
  }

  // Mongoose duplicate key error
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue).join(', ');
    const message = `Duplicate value for field: ${field}. Please use a different value`;
    error = ApiError.conflict(message);
  }

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const errors = Object.values(err.errors).map((e) => ({
      field: e.path,
      message: e.message,
    }));
    error = ApiError.badRequest('Validation Error', errors);
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    error = ApiError.unauthorized('Invalid token');
  }
  if (err.name === 'TokenExpiredError') {
    error = ApiError.unauthorized('Token has expired');
  }

  // Multer errors
  if (err.code === 'LIMIT_FILE_SIZE') {
    error = ApiError.badRequest('File size exceeds the limit');
  }
  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    error = ApiError.badRequest('Unexpected file field');
  }

  const statusCode = error.statusCode || 500;
  const message = error.message || 'Internal Server Error';

  // Log error
  if (statusCode >= 500) {
    logger.error(`[${req.method}] ${req.originalUrl} - ${statusCode} - ${message}`, {
      stack: err.stack,
      body: req.body,
      params: req.params,
      query: req.query,
    });
  } else {
    logger.warn(`[${req.method}] ${req.originalUrl} - ${statusCode} - ${message}`);
  }

  const response = {
    success: false,
    statusCode,
    message,
  };

  if (error.errors && error.errors.length > 0) {
    response.errors = error.errors;
  }

  if (process.env.NODE_ENV === 'development') {
    response.stack = err.stack;
  }

  console.log(`[TRACE][errorHandler] SENDING RESPONSE — statusCode=${statusCode}, message=${message}, errorsCount=${response.errors?.length || 0}`);
  res.status(statusCode).json(response);
};

/**
 * 404 Not Found handler for unmatched routes.
 */
const notFoundHandler = (req, res, next) => {
  const error = ApiError.notFound(`Route not found: ${req.method} ${req.originalUrl}`);
  next(error);
};

module.exports = { errorHandler, notFoundHandler };
