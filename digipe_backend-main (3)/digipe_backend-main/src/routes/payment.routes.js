const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/payment.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validation.middleware');
const paymentValidator = require('../validators/payment.validator');

/**
 * @swagger
 * /api/payments:
 *   post:
 *     tags: [Payments]
 *     summary: Create a Cashfree payment order (Customer)
 *     description: Creates a Cashfree payment order and returns payment_session_id for frontend checkout
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [orderId]
 *             properties:
 *               orderId: { type: string, description: Internal Order ID }
 *               paymentMethod: { type: string, enum: [CREDIT_CARD, DEBIT_CARD, NET_BANKING, UPI, WALLET], description: Optional payment method hint }
 *     responses:
 *       201:
 *         description: Payment session created with payment_session_id and cashfreeOrderId
 *       400:
 *         description: Order cancelled
 *       409:
 *         description: Order already paid
 */
router.post('/', authenticate, validate(paymentValidator.createPayment), paymentController.createPayment);

/**
 * @swagger
 * /api/payments/status/{orderId}:
 *   get:
 *     tags: [Payments]
 *     summary: Verify payment status from Cashfree (Customer)
 *     description: Queries Cashfree for latest payment status and updates local records
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema: { type: string }
 *         description: Internal Order ID
 *     responses:
 *       200:
 *         description: Current payment status
 *       404:
 *         description: Payment not found
 */
router.get('/status/:orderId', authenticate, validate(paymentValidator.verifyPayment), paymentController.verifyPayment);

/**
 * @swagger
 * /api/payments/webhook:
 *   post:
 *     tags: [Payments]
 *     summary: Cashfree webhook handler
 *     description: Receives payment status notifications from Cashfree. No authentication required — signature verification is done internally.
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Webhook processed
 *       400:
 *         description: Invalid webhook data
 *       401:
 *         description: Invalid webhook signature
 */
router.post('/webhook', paymentController.handleWebhook);

/**
 * @swagger
 * /api/payments/{id}:
 *   get:
 *     tags: [Payments]
 *     summary: Get payment details
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Payment details
 */
router.get('/:id', authenticate, validate(paymentValidator.getPayment), paymentController.getById);

/**
 * @swagger
 * /api/payments/order/{orderId}:
 *   get:
 *     tags: [Payments]
 *     summary: Get payment for a specific order
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Payment for order
 */
router.get('/order/:orderId', authenticate, validate(paymentValidator.getPaymentByOrder), paymentController.getByOrder);

module.exports = router;
