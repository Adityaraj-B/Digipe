const express = require('express');
const router = express.Router();
const policyController = require('../controllers/policy.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { authorizeAdmin } = require('../middlewares/admin.middleware');

/**
 * @swagger
 * /api/policies/my:
 *   get:
 *     tags: [Policies]
 *     summary: Get my policies (Customer)
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
 *         schema: { type: string, enum: [ACTIVE, EXPIRED, CANCELLED, CLAIMED] }
 *     responses:
 *       200:
 *         description: My policies
 */
router.get('/my', authenticate, policyController.getMyPolicies);

/**
 * @swagger
 * /api/policies:
 *   get:
 *     tags: [Policies]
 *     summary: Get all policies (Admin only)
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
 *         name: user
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: All policies
 */
router.get('/', authenticate, authorizeAdmin, policyController.getAll);

/**
 * @swagger
 * /api/policies/{id}:
 *   get:
 *     tags: [Policies]
 *     summary: Get policy details
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Policy details with plan, order, and claims
 */
router.get('/:id', authenticate, policyController.getById);

module.exports = router;
