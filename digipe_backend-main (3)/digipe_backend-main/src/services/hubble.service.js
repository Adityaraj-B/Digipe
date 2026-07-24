const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
const env = require('../config/env');
const logger = require('../config/logger');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');

/**
 * Attempts to load the RSA private key for Hubble SSO JWT signing.
 * Returns null if not found (falls back to mock token in dev).
 */
const loadPrivateKey = () => {
  try {
    const keyPath = path.resolve(env.hubble.ssoPrivateKeyPath);
    if (fs.existsSync(keyPath)) {
      return fs.readFileSync(keyPath, 'utf8');
    }
    logger.warn(`Hubble SSO private key not found at: ${keyPath}. Using mock token for dev.`);
    return null;
  } catch (error) {
    logger.warn(`Failed to load Hubble SSO private key: ${error.message}`);
    return null;
  }
};

/**
 * Generates an SSO token (JWT RS256) for a user to authenticate with Hubble SDK.
 * Per Hubble docs: token must be RS256 signed, 60-second expiry, single-use.
 *
 * @param {Object} user - The DigiPe user object
 * @returns {{ token: string, sdkUrl: string }} Token and full SDK URL
 */
const generateSSOToken = (user) => {
  if (!env.hubble.clientId) {
    throw ApiError.internal(messages.HUBBLE.SDK_CONFIG_MISSING);
  }

  const privateKey = loadPrivateKey();

  // If no private key is available, use the mock token for dev/staging
  if (!privateKey) {
    const mockToken = `mock-${env.hubble.clientId}`;
    logger.info(`Using mock Hubble SSO token for user: ${user._id}`);
    return {
      token: mockToken,
      sdkUrl: buildSDKUrl(mockToken),
    };
  }

  // Build JWT payload per Hubble SSO spec
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    sub: user._id.toString(),
    iss: env.hubble.clientId,
    iat: now,
    exp: now + 60, // Hubble requires exactly 60 seconds
    phoneNumber: user.mobileNumber
      ? user.mobileNumber.replace(/^\+91/, '') // Hubble wants 10-digit number without country code
      : undefined,
    name: user.name || undefined,
    email: user.email || undefined,
  };

  // Sign with RS256
  const token = jwt.sign(payload, privateKey, { algorithm: 'RS256' });

  logger.info(`Generated Hubble SSO token for user: ${user._id}`);
  return {
    token,
    sdkUrl: buildSDKUrl(token),
  };
};

/**
 * Builds the full Hubble SDK URL with all required query params.
 *
 * @param {string} token - The SSO token
 * @returns {string} Complete SDK URL for iframe embedding
 */
const buildSDKUrl = (token) => {
  const baseUrl = env.hubble.sdkBaseUrl.replace(/\/$/, '');
  const params = new URLSearchParams({
    clientId: env.hubble.clientId,
    clientSecret: env.hubble.clientSecret,
    token: token,
  });

  return `${baseUrl}/?${params.toString()}`;
};

module.exports = {
  generateSSOToken,
  buildSDKUrl,
};
