const express = require('express');
const router = express.Router();
const hubbleWebhookController = require('../controllers/hubbleWebhook.controller');

/**
 * @route   POST /api/hubble/webhook
 * @desc    Receive webhook events from Hubble SDK (payment, voucher, refund events)
 * @access  Public (webhook endpoint — should be secured with signature verification in production)
 */
router.post('/webhook', hubbleWebhookController.handleWebhook);

module.exports = router;
