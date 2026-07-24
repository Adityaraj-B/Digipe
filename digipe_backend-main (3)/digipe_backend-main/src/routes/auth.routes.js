const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validation.middleware');
const authValidator = require('../validators/auth.validator');

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     tags: [Auth]
 *     summary: Register a new user
 *     description: >
 *       Registers a new user via Surefy. Sends an OTP to phone or email for verification.
 *       If the user already exists, returns 409 Conflict.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [fullName]
 *             properties:
 *               fullName:
 *                 type: string
 *                 example: "Test User"
 *                 description: Full name (min 3 characters)
 *               phone:
 *                 type: string
 *                 example: "7990554048"
 *                 description: 10-digit phone number (do not include country code)
 *               email:
 *                 type: string
 *                 example: "user@example.com"
 *                 description: Email address
 *     responses:
 *       200:
 *         description: OTP sent for verification
 *       400:
 *         description: Validation error — fullName missing, or neither phone nor email provided
 *       409:
 *         description: User already registered — use login instead
 */
router.post('/register', validate(authValidator.register), authController.registerUser);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     tags: [Auth]
 *     summary: Login — Send OTP to mobile number or email
 *     description: >
 *       Checks if user exists in Surefy. If yes, sends a 6-digit OTP.
 *       If user not found, returns 404 "Please register first".
 *       Provide either mobileNumber or email.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               mobileNumber:
 *                 type: string
 *                 description: Mobile number with country code (provide this OR email)
 *               email:
 *                 type: string
 *                 description: Email address (provide this OR mobileNumber)
 *           examples:
 *             loginWithPhone:
 *               summary: Login with phone number
 *               value:
 *                 mobileNumber: "+919876543210"
 *             loginWithEmail:
 *               summary: Login with email
 *               value:
 *                 email: "user@example.com"
 *     responses:
 *       200:
 *         description: OTP sent successfully
 *       400:
 *         description: Neither mobile number nor email provided
 *       404:
 *         description: User not found — please register first
 *       429:
 *         description: Too many OTP requests
 */
router.post('/login', validate(authValidator.sendOtp), authController.sendOtp);
// Backward-compatible alias
router.post('/send-otp', validate(authValidator.sendOtp), authController.sendOtp);

/**
 * @swagger
 * /api/auth/verify-otp:
 *   post:
 *     tags: [Auth]
 *     summary: Verify OTP and login
 *     description: >
 *       Verifies the OTP via Surefy Auth, creates user if new, generates JWT token.
 *       Every login attempt (success or failure) is logged with a unique session ID (LOG-XXXXXX).
 *       Provide either mobileNumber or email (same as used to request OTP), along with the 6-digit OTP code.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [code]
 *             properties:
 *               mobileNumber:
 *                 type: string
 *                 description: Mobile number with country code (provide this OR email)
 *               email:
 *                 type: string
 *                 description: Email address (provide this OR mobileNumber)
 *               code:
 *                 type: string
 *                 description: 6-digit OTP received by the user
 *           examples:
 *             verifyWithPhone:
 *               summary: Verify OTP with phone number
 *               value:
 *                 mobileNumber: "+919876543210"
 *                 code: "123456"
 *             verifyWithEmail:
 *               summary: Verify OTP with email
 *               value:
 *                 email: "user@example.com"
 *                 code: "123456"
 *     responses:
 *       200:
 *         description: OTP verified, returns user, JWT token, session ID, and login status
 *       400:
 *         description: Invalid or expired OTP, or neither mobileNumber nor email provided
 *       429:
 *         description: Too many OTP requests
 */
router.post('/verify-otp', validate(authValidator.verifyOtp), authController.verifyOtp);

/**
 * @swagger
 * /api/auth/profile:
 *   get:
 *     tags: [Auth]
 *     summary: Get current user profile
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Profile fetched successfully
 *       401:
 *         description: Unauthorized
 */
router.get('/profile', authenticate, authController.getProfile);

/**
 * @swagger
 * /api/auth/profile:
 *   put:
 *     tags: [Auth]
 *     summary: Update current user profile
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               email:
 *                 type: string
 *               profileImage:
 *                 type: string
 *     responses:
 *       200:
 *         description: Profile updated successfully
 *       401:
 *         description: Unauthorized
 */
router.put('/profile', authenticate, validate(authValidator.updateProfile), authController.updateProfile);

module.exports = router;
