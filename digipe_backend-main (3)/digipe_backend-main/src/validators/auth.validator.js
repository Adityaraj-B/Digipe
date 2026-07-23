const Joi = require('joi');

const register = {
  body: Joi.object({
    fullName: Joi.string()
      .trim()
      .min(3)
      .required()
      .messages({
        'string.min': 'Full name must be at least 3 characters',
        'any.required': 'Full name is required',
      }),
    phone: Joi.string()
      .trim()
      .pattern(/^\d{10}$/)
      .optional()
      .messages({
        'string.pattern.base': 'Phone number must be exactly 10 digits. Do not include country code',
      }),
    email: Joi.string()
      .email()
      .trim()
      .optional()
      .messages({
        'string.email': 'Please provide a valid email address',
      }),
  }).or('phone', 'email')
    .messages({
      'object.missing': 'Either phone or email is required',
    }),
};

const sendOtp = {
  body: Joi.object({
    mobileNumber: Joi.string()
      .pattern(/^(\+[1-9]\d{6,14}|\d{10})$/)
      .optional()
      .messages({
        'string.pattern.base': 'Mobile number must be 10 digits (e.g., 9876543210) or international format (e.g., +91XXXXXXXXXX)',
      }),
    email: Joi.string()
      .email()
      .trim()
      .optional()
      .messages({
        'string.email': 'Please provide a valid email address',
      }),
  }).or('mobileNumber', 'email')
    .messages({
      'object.missing': 'Either mobile number or email is required',
    }),
};

const verifyOtp = {
  body: Joi.object({
    mobileNumber: Joi.string()
      .pattern(/^(\+[1-9]\d{6,14}|\d{10})$/)
      .optional()
      .messages({
        'string.pattern.base': 'Mobile number must be 10 digits (e.g., 9876543210) or international format (e.g., +91XXXXXXXXXX)',
      }),
    email: Joi.string()
      .email()
      .trim()
      .optional()
      .messages({
        'string.email': 'Please provide a valid email address',
      }),
    code: Joi.string()
      .length(6)
      .pattern(/^\d+$/)
      .required()
      .messages({
        'string.length': 'OTP must be 6 digits',
        'string.pattern.base': 'OTP must contain only digits',
        'any.required': 'OTP code is required',
      }),
  }).or('mobileNumber', 'email')
    .messages({
      'object.missing': 'Either mobile number or email is required',
    }),
};

const updateProfile = {
  body: Joi.object({
    name: Joi.string().trim().max(100).optional(),
    email: Joi.string().email().trim().optional(),
    profileImage: Joi.string().uri().optional(),
  }),
};

module.exports = {
  register,
  sendOtp,
  verifyOtp,
  updateProfile,
};
