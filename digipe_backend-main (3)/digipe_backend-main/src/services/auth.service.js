const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const env = require('../config/env');
const logger = require('../config/logger');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const { ROLES, LOGIN_STATUS, DISPLAY_ROLES } = require('../constants');
const userRepository = require('../repositories/user.repository');
const userSessionRepository = require('../repositories/userSession.repository');
const loginLogRepository = require('../repositories/loginLog.repository');
const surefyAuthClient = require('./surefyAuth.client');
const { normalizePhone } = require('../utils/helpers');

class AuthService {
  /**
   * Register a new user with Surefy.
   * Flow: Register API → Call Surefy Register API → OTP Sent
   * @param {Object} params
   * @param {string} params.fullName - Full name (min 3 chars)
   * @param {string} [params.phone] - 10-digit phone number (no country code)
   * @param {string} [params.email] - Email address
   * @returns {Promise<Object>} { identifier, message }
   */
  async registerUser({ fullName, phone, email }) {
    console.log(`[TRACE][service.registerUser] ENTER — phone=${phone}, email=${email}`);

    // 1. If user already exists in our DB → tell them to login
    if (phone) {
      const existingUser = await userRepository.findByMobileNumber(phone);
      if (existingUser && existingUser.isActive) {
        console.log(`[TRACE][service.registerUser] User already exists in local DB — rejecting`);
        throw ApiError.conflict(messages.AUTH.USER_ALREADY_EXISTS);
      }
    }

    // 2. Register with Surefy → sends OTP to email
    try {
      await surefyAuthClient.register({ fullName, phone, email });
      console.log(`[TRACE][service.registerUser] Surefy register SUCCESS — OTP sent to email`);
    } catch (error) {
      if (error.statusCode === 409) {
        // Already registered in Surefy → tell them to login
        console.log(`[TRACE][service.registerUser] Already registered in Surefy — rejecting`);
        throw ApiError.conflict(messages.AUTH.USER_ALREADY_EXISTS);
      }
      throw error;
    }

    // 3. Return success — frontend will show OTP form
    return {
      isNewUser: true,
      identifier: phone || email,
      message: messages.AUTH.OTP_SENT,
    };
  }

  /**
   * Send OTP to the given mobile number or email via Surefy Auth.
   * @param {string} identifier - Mobile number (with country code) or email address
   * @returns {Promise<Object>}
   */
  async sendOtp(identifier) {
    // surefyAuthClient.login() handles both phone and email identifiers.
    // On failure it throws an ApiError (mapped from Surefy's response codes).
    await surefyAuthClient.login(identifier);

    logger.info(`OTP requested for ${identifier} via Surefy`);

    return {
      status: 'pending',
      ...(this._isEmail(identifier) ? { email: identifier } : { mobileNumber: identifier }),
    };
  }

  /**
   * Verify OTP and authenticate the user.
   * Flow: Verify OTP via Surefy → Find/Create User → Generate our JWT → Create Session → Log Login → Return Token
   * @param {string} identifier - Mobile number or email
   * @param {string} code - OTP code
   * @param {Object} meta - { ipAddress, userAgent }
   * @returns {Promise<Object>} { user, token, isNewUser, sessionId, status, timestamp }
   */
  async verifyOtp(identifier, code, meta = {}) {
    console.log(`[TRACE][service.verifyOtp] ========== ENTER ==========`);
    console.log(`[TRACE][service.verifyOtp] identifier=${identifier}, code=${code}, timestamp=${new Date().toISOString()}`);
    const sessionId = this._generateSessionId();
    const isEmail = this._isEmail(identifier);
    console.log(`[TRACE][service.verifyOtp] sessionId=${sessionId}, isEmail=${isEmail}`);

    try {
      // Delegate OTP verification to Surefy.
      // Returns { accessToken, refreshToken } from Surefy — we discard these
      // because we issue our own JWT (Option B).
      console.log(`[TRACE][service.verifyOtp] STEP 1: Calling surefyAuthClient.verifyOtp()`);
      await surefyAuthClient.verifyOtp(identifier, code);
      console.log(`[TRACE][service.verifyOtp] STEP 1 COMPLETE: Surefy verifyOtp returned successfully`);
    } catch (error) {
      console.log(`[TRACE][service.verifyOtp] STEP 1 FAILED: Surefy verifyOtp threw — name=${error.name}, message=${error.message}, statusCode=${error.statusCode}`);
      // Log failed login attempt
      await this._logLoginAttempt({
        sessionId,
        user: null,
        identifier,
        role: null,
        status: LOGIN_STATUS.FAILED,
        failReason: error.message || messages.AUTH.INVALID_OTP,
        ipAddress: meta.ipAddress,
        userAgent: meta.userAgent,
      });
      console.log(`[TRACE][service.verifyOtp] Failed login logged. Re-throwing error.`);

      throw error;
    }

    // Find user — try both email and phone since registration provides both
    console.log(`[TRACE][service.verifyOtp] STEP 2: Finding user — identifier=${identifier}, meta.mobileNumber=${meta.mobileNumber}, meta.email=${meta.email}`);
    let user;
    if (isEmail) {
      user = await userRepository.findByEmail(identifier.trim().toLowerCase());
      // If not found by email, also try phone (user may have registered with phone before)
      if (!user && meta.mobileNumber) {
        user = await userRepository.findByMobileNumber(meta.mobileNumber);
      }
    } else {
      user = await userRepository.findByMobileNumber(identifier);
      // If not found by phone, also try email
      if (!user && meta.email) {
        user = await userRepository.findByEmail(meta.email.trim().toLowerCase());
      }
    }
    console.log(`[TRACE][service.verifyOtp] STEP 2 COMPLETE: user=${user ? user._id : 'NOT FOUND'}`);
    let isNewUser = false;

    if (!user) {
      // Create new user with BOTH phone and email
      console.log(`[TRACE][service.verifyOtp] STEP 3: Creating new user`);
      const userData = {
        role: ROLES.CUSTOMER,
        isActive: true,
      };
      if (meta.mobileNumber) {
        userData.mobileNumber = normalizePhone(meta.mobileNumber);
      } else if (!isEmail) {
        userData.mobileNumber = normalizePhone(identifier);
      }
      if (meta.email) {
        userData.email = meta.email.trim().toLowerCase();
      } else if (isEmail) {
        userData.email = identifier.trim().toLowerCase();
      }
      user = await userRepository.create(userData);
      isNewUser = true;
      console.log(`[TRACE][service.verifyOtp] STEP 3 COMPLETE: User CREATED — _id=${user._id}, phone=${user.mobileNumber}, email=${user.email}`);
      logger.info(`New user created: ${user._id}`);
    } else {
      console.log(`[TRACE][service.verifyOtp] STEP 3: SKIPPED — user already exists`);
    }

    if (!user.isActive) {
      console.log(`[TRACE][service.verifyOtp] User is DEACTIVATED — throwing forbidden`);
      // Log failed login — account deactivated
      await this._logLoginAttempt({
        sessionId,
        user: user._id,
        identifier,
        role: DISPLAY_ROLES[user.role] || user.role,
        status: LOGIN_STATUS.FAILED,
        failReason: messages.AUTH.ACCOUNT_DEACTIVATED,
        ipAddress: meta.ipAddress,
        userAgent: meta.userAgent,
      });

      throw ApiError.forbidden(messages.AUTH.ACCOUNT_DEACTIVATED);
    }

    // Generate JWT token
    console.log(`[TRACE][service.verifyOtp] STEP 4: Generating JWT`);
    const token = this._generateToken(user);
    console.log(`[TRACE][service.verifyOtp] STEP 4 COMPLETE: JWT generated (length=${token.length})`);

    // Calculate expiry from JWT_EXPIRES_IN
    const expiresIn = this._parseExpiresIn(env.jwt.expiresIn);
    const expiresAt = new Date(Date.now() + expiresIn);

    // Create session
    console.log(`[TRACE][service.verifyOtp] STEP 5: Creating session`);
    await userSessionRepository.create({
      user: user._id,
      token,
      deviceInfo: meta.userAgent || null,
      ipAddress: meta.ipAddress || null,
      isActive: true,
      expiresAt,
    });
    console.log(`[TRACE][service.verifyOtp] STEP 5 COMPLETE: Session created`);

    // Log successful login
    const displayRole = DISPLAY_ROLES[user.role] || user.role;
    console.log(`[TRACE][service.verifyOtp] STEP 6: Logging successful login`);
    await this._logLoginAttempt({
      sessionId,
      user: user._id,
      identifier,
      role: displayRole,
      status: LOGIN_STATUS.SUCCESS,
      failReason: null,
      ipAddress: meta.ipAddress,
      userAgent: meta.userAgent,
    });
    console.log(`[TRACE][service.verifyOtp] STEP 6 COMPLETE: Login logged`);

    logger.info(`User ${user._id} authenticated successfully (session: ${sessionId})`);

    // Format timestamp like the UI: "Jun 4 2026, 12:11 PM"
    const timestamp = new Date().toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    });

    console.log(`[TRACE][service.verifyOtp] STEP 7: Building response object`);
    const result = {
      user,
      token,
      isNewUser,
      sessionId,
      role: displayRole,
      status: LOGIN_STATUS.SUCCESS,
      timestamp,
    };
    console.log(`[TRACE][service.verifyOtp] STEP 7 COMPLETE: Returning success — userId=${user._id}, isNewUser=${isNewUser}`);
    console.log(`[TRACE][service.verifyOtp] ========== EXIT (SUCCESS) ==========`);
    return result;
  }

  /**
   * Get user profile by ID.
   * @param {string} userId
   * @returns {Promise<Object>}
   */
  async getProfile(userId) {
    const user = await userRepository.findById(userId);
    if (!user) {
      throw ApiError.notFound(messages.AUTH.UNAUTHORIZED);
    }
    return user;
  }

  /**
   * Update user profile.
   * @param {string} userId
   * @param {Object} updateData
   * @returns {Promise<Object>}
   */
  async updateProfile(userId, updateData) {
    const allowedFields = ['name', 'email', 'profileImage'];
    const filteredData = {};

    allowedFields.forEach((field) => {
      if (updateData[field] !== undefined) {
        filteredData[field] = updateData[field];
      }
    });

    const user = await userRepository.updateById(userId, filteredData);
    if (!user) {
      throw ApiError.notFound(messages.AUTH.UNAUTHORIZED);
    }

    logger.info(`User ${userId} profile updated`);
    return user;
  }

  // ─── Private helpers ────────────────────────────────────────

  /**
   * Generate a unique session ID in LOG-XXXXXX format.
   * @returns {string}
   */
  _generateSessionId() {
    const hex = crypto.randomBytes(3).toString('hex').toUpperCase();
    return `LOG-${hex}`;
  }

  /**
   * Check whether an identifier looks like an email address.
   * @param {string} identifier
   * @returns {boolean}
   */
  _isEmail(identifier) {
    return typeof identifier === 'string' && identifier.includes('@');
  }

  /**
   * Log a login attempt to the LoginLog collection.
   * @param {Object} data
   * @returns {Promise<Object>}
   */
  async _logLoginAttempt(data) {
    try {
      return await loginLogRepository.create(data);
    } catch (error) {
      // Don't let logging failures break the login flow
      logger.error(`Failed to log login attempt: ${error.message}`);
    }
  }

  /**
   * Generate JWT token for a user.
   * @param {Object} user
   * @returns {string}
   */
  _generateToken(user) {
    return jwt.sign(
      {
        id: user._id,
        role: user.role,
        mobileNumber: user.mobileNumber,
      },
      env.jwt.secret,
      { expiresIn: env.jwt.expiresIn }
    );
  }

  /**
   * Parse JWT expiresIn string to milliseconds.
   * @param {string} expiresIn - e.g., '24h', '7d', '30m'
   * @returns {number} milliseconds
   */
  _parseExpiresIn(expiresIn) {
    const match = expiresIn.match(/^(\d+)(s|m|h|d)$/);
    if (!match) return 24 * 60 * 60 * 1000; // default 24h

    const value = parseInt(match[1], 10);
    const unit = match[2];

    const multipliers = { s: 1000, m: 60000, h: 3600000, d: 86400000 };
    return value * (multipliers[unit] || 3600000);
  }
}

module.exports = new AuthService();
