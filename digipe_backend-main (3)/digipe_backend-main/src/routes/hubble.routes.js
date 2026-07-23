const express = require('express');
const router = express.Router();
const { authenticate } = require('../middlewares/auth.middleware');
const hubbleController = require('../controllers/hubble.controller');

/**
 * @route   GET /api/hubble/sdk-token
 * @desc    Generate Hubble SSO token and SDK URL (embedded WebView URL) for authenticated user
 * @access  Private (requires Bearer token)
 */
router.get('/sdk-token', authenticate, hubbleController.getHubbleSDKToken);

/**
 * @route   GET /api/hubble/transactions
 * @desc    Get the authenticated user's Hubble transaction history (from webhook records)
 * @access  Private (requires Bearer token)
 */
router.get('/transactions', authenticate, hubbleController.getMyTransactions);

module.exports = router;
