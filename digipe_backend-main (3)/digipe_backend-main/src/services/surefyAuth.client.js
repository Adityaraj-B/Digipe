const axios = require('axios');
const env = require('../config/env');
const logger = require('../config/logger');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');

/**
 * HTTP client for the Surefy Auth (Digipe) service.
 *
 * Wraps login (send OTP), verify-otp, refresh, and logout endpoints.
 * All Surefy-specific error codes are mapped to our ApiError classes
 * so callers don't need to know about the external API shape.
 */
class SurefyAuthClient {
  constructor() {
    this.client = axios.create({
      baseURL: env.surefy.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': env.surefy.apiKey,
      },
      timeout: 15000, // 15 s — generous for OTP delivery
    });

    // Debug interceptor — log every outgoing request
    this.client.interceptors.request.use((config) => {
      logger.info(`[DEBUG] Surefy → ${config.method.toUpperCase()} ${config.baseURL}${config.url}`);
      logger.info(`[DEBUG] Headers: ${JSON.stringify(config.headers)}`);
      logger.info(`[DEBUG] Body: ${JSON.stringify(config.data)}`);
      return config;
    });
  }

  // ─── Public methods ──────────────────────────────────────────

  /**
   * Register a new user with Surefy and send OTP for verification.
   *
   * @param {Object} params
   * @param {string} params.fullName - Full name (min 3 chars)
   * @param {string} [params.phone] - Phone number without country code (e.g. "7990554048")
   * @param {string} [params.email] - Email address
   * @returns {Promise<Object>} Surefy success envelope
   */
  async register({ fullName, phone, email }) {
    // Surefy's /auth/register only accepts phone+countryCode OR email —
    // never both in the same request. Prefer email since that's how OTP
    // delivery (and the rest of this app's registration flow) is wired.
    const payload = { fullName };
    if (email) {
      payload.email = email;
    } else if (phone) {
      payload.phone = phone;
      payload.countryCode = '+91';
    }

    console.log(`[TRACE][surefy.register] Sending to Surefy: ${JSON.stringify(payload)}`);
    try {
      const { data } = await this.client.post('/auth/register', payload);
      console.log(`[TRACE][surefy.register] SUCCESS — responseCode=${data.responseCode}, data=${JSON.stringify(data)}`);
      logger.info(`Surefy register for ${phone || email}, response: ${data.responseCode}`);
      return data;
    } catch (error) {
      console.log(`[TRACE][surefy.register] FAILED — status=${error.response?.status}, data=${JSON.stringify(error.response?.data)}`);
      this._handleError(error, 'register', phone || email);
    }
  }

  /**
   * Request an OTP for the given phone number or email.
   * Surefy delivers the OTP via WhatsApp (phone) or email.
   *
   * @param {string} identifier - Phone (with/without country code) or email address
   * @returns {Promise<Object>} Surefy success envelope
   */
  async login(identifier) {
    const loginInfo = this._isEmail(identifier)
      ? identifier.trim().toLowerCase()
      : this._normalizePhone(identifier);

    console.log(`[TRACE][surefy.login] Sending to Surefy: loginInfo=${loginInfo}`);
    try {
      const { data } = await this.client.post('/auth/login', { loginInfo });
      console.log(`[TRACE][surefy.login] SUCCESS — responseCode=${data.responseCode}, FULL BODY: ${JSON.stringify(data)}`);
      logger.info(`[OTP-DELIVERY] login() for ${loginInfo}: channel=${data.responseData?.channel || data.channel || 'unknown'}, ` +
                  `delivered=${data.responseData?.delivered ?? 'unknown'}, full=${JSON.stringify(data)}`);
      logger.info(`Surefy OTP requested for ${loginInfo}, response: ${data.responseCode}`);
      return data;
    } catch (error) {
      console.log(`[TRACE][surefy.login] FAILED — status=${error.response?.status}, data=${JSON.stringify(error.response?.data)}`);
      this._handleError(error, 'login', loginInfo);
    }
  }

  /**
   * Verify the OTP the user received.
   *
   * @param {string} identifier - Phone (with/without country code) or email address
   * @param {string} otp        - 6-digit OTP string
   * @returns {Promise<Object>} { accessToken, refreshToken } from Surefy
   */
  async verifyOtp(identifier, otp) {
    let payload;
    if (this._isEmail(identifier)) {
      payload = { email: identifier.trim().toLowerCase(), otp };
    } else {
      payload = { phone: this._normalizePhone(identifier), otp, countryCode: '+91' };
    }

    console.log(`[TRACE][surefy.verifyOtp] ENTER — identifier=${identifier}, otp=${otp}`);
    console.log(`[TRACE][surefy.verifyOtp] Normalized payload: ${JSON.stringify(payload)}`);
    logger.info(`[DEBUG] Surefy verify-otp request: ${JSON.stringify(payload)}`);

    try {
      const { data } = await this.client.post('/auth/verify-otp', payload);
      console.log(`[TRACE][surefy.verifyOtp] SUCCESS — responseCode=${data.responseCode}, hasAccessToken=${!!data.responseData?.accessToken}`);
      logger.info(`Surefy OTP verified for ${identifier}`);
      return data.responseData; // { accessToken, refreshToken }
    } catch (error) {
      console.log(`[TRACE][surefy.verifyOtp] FAILED — status=${error.response?.status}, responseCode=${error.response?.data?.responseCode}, message=${error.response?.data?.message}`);
      if (error.response) {
        logger.error(`[DEBUG] Surefy verify-otp raw response: ${JSON.stringify(error.response.data)}`);
      }
      console.log(`[TRACE][surefy.verifyOtp] Calling _handleError() which will throw`);
      this._handleError(error, 'verifyOtp', identifier);
    }
  }

  /**
   * Refresh an access token using a Surefy refresh token.
   *
   * @param {string} refreshToken - Surefy-issued refresh JWT
   * @returns {Promise<Object>} { accessToken } from Surefy
   */
  async refreshToken(refreshToken) {
    try {
      const { data } = await this.client.post('/auth/refresh', { refreshToken });
      return data.responseData;
    } catch (error) {
      this._handleError(error, 'refreshToken');
    }
  }

  /**
   * Revoke the refresh token associated with the given access token.
   *
   * @param {string} accessToken - Surefy-issued access JWT
   * @returns {Promise<void>}
   */
  async logout(accessToken) {
    try {
      await this.client.post('/auth/logout', null, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      logger.info('Surefy session logged out');
    } catch (error) {
      // Logout failures are non-critical — log and swallow
      logger.warn(`Surefy logout failed: ${error.message}`);
    }
  }

  // ─── Private helpers ─────────────────────────────────────────

  /**
   * Check whether an identifier looks like an email address.
   * @param {string} identifier
   * @returns {boolean}
   */
  _isEmail(identifier) {
    return typeof identifier === 'string' && identifier.includes('@');
  }

  /**
   * Normalize phone number for Surefy API.
   * Surefy register & verify-otp expect 10-digit phone WITHOUT country code.
   * Handles: "+918604707494" → "8604707494", "918604707494" → "8604707494", "8604707494" → "8604707494"
   */
  _normalizePhone(phone) {
    let digits = phone.replace(/\D/g, ''); // strip all non-digits
    // Remove leading "91" country code if number is longer than 10 digits
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.slice(2);
    }
    return digits;
  }

  /**
   * Map Surefy HTTP errors to our ApiError hierarchy.
   * Always throws — callers should not continue after this.
   */
  _handleError(error, operation, identifier = '') {
    if (error.response) {
      const { status, data } = error.response;
      const code = data?.responseCode || '';
      const msg = data?.message || '';

      console.log(`[TRACE][surefy._handleError] ENTER — operation=${operation}, status=${status}, code=${code}, msg=${msg}`);
      logger.error(
        `Surefy ${operation} failed [${status}] for ${identifier}: ${code} — ${msg}`
      );

      switch (status) {
        case 400:
          if (code === 'INVALID_OTP') {
            console.log(`[TRACE][surefy._handleError] THROWING badRequest — INVALID_OTP`);
            throw ApiError.badRequest(messages.AUTH.INVALID_OTP);
          }
          // Surefy returns 400 when user already exists during registration
          if (msg && msg.toLowerCase().includes('already registered')) {
            console.log(`[TRACE][surefy._handleError] THROWING conflict — already registered`);
            throw ApiError.conflict(messages.AUTH.USER_ALREADY_EXISTS);
          }
          console.log(`[TRACE][surefy._handleError] THROWING badRequest — generic 400`);
          throw ApiError.badRequest(msg || messages.GENERAL.BAD_REQUEST);

        case 401:
          // 401 from Surefy = our API key is missing or invalid (server misconfiguration)
          console.log(`[TRACE][surefy._handleError] THROWING internal — 401 API key issue`);
          logger.error('Surefy API key is missing or invalid — check SUREFY_API_KEY env var');
          throw ApiError.internal(messages.AUTH.AUTH_SERVICE_ERROR);

        case 403:
          console.log(`[TRACE][surefy._handleError] THROWING forbidden — 403`);
          throw ApiError.forbidden(messages.AUTH.FORBIDDEN);

        case 404:
          console.log(`[TRACE][surefy._handleError] THROWING notFound — 404`);
          throw ApiError.notFound(messages.AUTH.USER_NOT_FOUND_AUTH);

        case 429:
          console.log(`[TRACE][surefy._handleError] THROWING tooManyRequests — 429`);
          throw ApiError.tooManyRequests(messages.AUTH.TOO_MANY_REQUESTS);

        default:
          // Surefy sometimes leaks raw DB errors (500 + "duplicate key") for existing users
          if (msg && msg.includes('duplicate key')) {
            console.log(`[TRACE][surefy._handleError] THROWING conflict — duplicate key`);
            throw ApiError.conflict(messages.AUTH.USER_ALREADY_EXISTS);
          }
          console.log(`[TRACE][surefy._handleError] THROWING internal — default case, status=${status}`);
          throw ApiError.internal(messages.AUTH.AUTH_SERVICE_ERROR);
      }
    }

    // Network / timeout errors
    console.log(`[TRACE][surefy._handleError] THROWING internal — network/timeout error: ${error.message}`);
    logger.error(`Surefy ${operation} network error for ${identifier}: ${error.message}`);
    throw ApiError.internal(messages.AUTH.AUTH_SERVICE_ERROR);
  }
}

module.exports = new SurefyAuthClient();
