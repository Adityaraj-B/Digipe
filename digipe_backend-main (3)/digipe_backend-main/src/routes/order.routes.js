const express = require('express');
const router = express.Router();
const orderController = require('../controllers/order.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { authorizeAdmin } = require('../middlewares/admin.middleware');
const validate = require('../middlewares/validation.middleware');
const orderValidator = require('../validators/order.validator');

/**
 * @swagger
 * /api/orders:
 *   post:
 *     tags: [Orders]
 *     summary: Create an order directly (Customer)
 *     description: Creates an order directly from one or more approved applications
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - items
 *             properties:
 *               items:
 *                 type: array
 *                 minItems: 1
 *                 items:
 *                   type: object
 *                   required:
 *                     - planId
 *                     - applicationId
 *                   properties:
 *                     planId:
 *                       type: string
 *                       description: The plan ID to purchase
 *                     applicationId:
 *                       type: string
 *                       description: The approved application ID for this plan
 *     responses:
 *       201:
 *         description: Order created successfully
 *       400:
 *         description: Validation error or application not approved
 *       403:
 *         description: Application does not belong to user
 *       404:
 *         description: Plan or application not found
 */
router.post('/', authenticate, validate(orderValidator.createOrder), orderController.createOrder);

/**
 * @swagger
 * /api/orders/my:
 *   get:
 *     tags: [Orders]
 *     summary: Get my orders (Customer)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema: { type: integer }
 *       - in: query
 *         name: limit
 *         schema: { type: integer }
 *       - in: query
 *         name: status
 *         schema: { type: string, enum: [PENDING, CONFIRMED, CANCELLED] }
 *     responses:
 *       200:
 *         description: My orders
 */
router.get('/my', authenticate, orderController.getMyOrders);

/**
 * @swagger
 * /api/orders:
 *   get:
 *     tags: [Orders]
 *     summary: Get all orders (Admin only)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema: { type: integer }
 *       - in: query
 *         name: limit
 *         schema: { type: integer }
 *       - in: query
 *         name: status
 *         schema: { type: string }
 *       - in: query
 *         name: paymentStatus
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: All orders
 */
router.get('/', authenticate, authorizeAdmin, orderController.getAll);

/**
 * @swagger
 * /api/orders/{id}:
 *   get:
 *     tags: [Orders]
 *     summary: Get order details
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Order details with items and payment
 */
router.get('/:id', authenticate, validate(orderValidator.getOrder), orderController.getById);

module.exports = router;