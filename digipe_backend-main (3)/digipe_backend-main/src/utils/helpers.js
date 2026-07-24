const { v4: uuidv4 } = require('uuid');

/**
 * Generate a URL-safe slug from text.
 * @param {string} text
 * @returns {string}
 */
const slugify = (text) => {
  return text
    .toString()
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')
    .replace(/[^\w-]+/g, '')
    .replace(/--+/g, '-')
    .replace(/^-+/, '')
    .replace(/-+$/, '');
};

/**
 * Generate unique application number.
 * Format: APP-XXXXXXXX
 * @returns {string}
 */
const generateApplicationNumber = () => {
  const id = uuidv4().replace(/-/g, '').substring(0, 8).toUpperCase();
  return `APP-${id}`;
};

/**
 * Generate unique order number.
 * Format: ORD-XXXXXXXX
 * @returns {string}
 */
const generateOrderNumber = () => {
  const id = uuidv4().replace(/-/g, '').substring(0, 8).toUpperCase();
  return `ORD-${id}`;
};

/**
 * Generate unique policy number.
 * Format: POL-XXXXXXXX
 * @returns {string}
 */
const generatePolicyNumber = () => {
  const id = uuidv4().replace(/-/g, '').substring(0, 8).toUpperCase();
  return `POL-${id}`;
};

/**
 * Generate unique claim number.
 * Format: CLM-XXXXXXXX
 * @returns {string}
 */
const generateClaimNumber = () => {
  const id = uuidv4().replace(/-/g, '').substring(0, 8).toUpperCase();
  return `CLM-${id}`;
};

/**
 * Generate unique transaction ID.
 * Format: TXN-XXXXXXXXXXXX
 * @returns {string}
 */
const generateTransactionId = () => {
  const id = uuidv4().replace(/-/g, '').substring(0, 12).toUpperCase();
  return `TXN-${id}`;
};

/**
 * Remove undefined and null values from an object.
 * Useful for building update objects.
 * @param {Object} obj
 * @returns {Object}
 */
const sanitizeObject = (obj) => {
  const sanitized = {};
  Object.entries(obj).forEach(([key, value]) => {
    if (value !== undefined && value !== null) {
      sanitized[key] = value;
    }
  });
  return sanitized;
};

/**
 * Check if a string is a valid MongoDB ObjectId.
 * @param {string} id
 * @returns {boolean}
 */
const isValidObjectId = (id) => {
  return /^[0-9a-fA-F]{24}$/.test(id);
};

/**
 * Normalize an Indian mobile number to +91XXXXXXXXXX format.
 * Handles inputs like: "8604707494", "+918604707494", "918604707494", "91 8604707494"
 * @param {string} phone
 * @returns {string} Normalized phone with +91 prefix
 */
const normalizePhone = (phone) => {
  if (!phone) return phone;
  let digits = phone.replace(/\D/g, ''); // strip all non-digit characters
  // Remove leading '91' country code if number is longer than 10 digits
  if (digits.length > 10 && digits.startsWith('91')) {
    digits = digits.slice(2);
  }
  return `+91${digits}`;
};

module.exports = {
  slugify,
  generateApplicationNumber,
  generateOrderNumber,
  generatePolicyNumber,
  generateClaimNumber,
  generateTransactionId,
  sanitizeObject,
  isValidObjectId,
  normalizePhone,
};
