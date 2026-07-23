const express = require('express');
const router = express.Router();
const planController = require('../controllers/plan.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { authorizeAdmin } = require('../middlewares/admin.middleware');
const validate = require('../middlewares/validation.middleware');
const planValidator = require('../validators/plan.validator');

/**
 * @swagger
 * /api/plans:
 *   get:
 *     tags: [Plans]
 *     summary: Get all insurance plans
 *     parameters:
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 10 }
 *       - in: query
 *         name: product
 *         schema: { type: string }
 *       - in: query
 *         name: sort
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Plans fetched
 */
router.get('/', planController.getAll);

/**
 * @swagger
 * /api/plans/product/{productId}:
 *   get:
 *     tags: [Plans]
 *     summary: Get plans by product
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Plans for product fetched
 */
router.get('/product/:productId', validate(planValidator.getByProduct), planController.getByProduct);

/**
 * @swagger
 * /api/plans/{id}:
 *   get:
 *     tags: [Plans]
 *     summary: Get plan details
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Plan details
 */
router.get('/:id', validate(planValidator.getPlan), planController.getById);

/**
 * @swagger
 * /api/plans:
 *   post:
 *     tags: [Plans]
 *     summary: Create a plan (Admin only)
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [product, name, coverageAmount, premium, duration]
 *             properties:
 *               product: { type: string }
 *               name: { type: string }
 *               description: { type: string }
 *               coverageAmount: { type: number }
 *               premium: { type: number }
 *               premiumFrequency: { type: string, enum: [MONTHLY, QUARTERLY, HALF_YEARLY, YEARLY] }
 *               duration: { type: integer, description: Duration in months }
 *               features: { type: array, items: { type: string } }
 *               benefits: { type: array, items: { type: string } }
 *               exclusions: { type: array, items: { type: string } }
 *     responses:
 *       201:
 *         description: Plan created
 */
router.post('/', authenticate, authorizeAdmin, validate(planValidator.createPlan), planController.create);

/**
 * @swagger
 * /api/plans/{id}:
 *   put:
 *     tags: [Plans]
 *     summary: Update a plan (Admin only)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name: { type: string }
 *               description: { type: string }
 *               coverageAmount: { type: number }
 *               premium: { type: number }
 *               premiumFrequency: { type: string }
 *               duration: { type: integer }
 *               features: { type: array, items: { type: string } }
 *               benefits: { type: array, items: { type: string } }
 *               exclusions: { type: array, items: { type: string } }
 *     responses:
 *       200:
 *         description: Plan updated
 */
router.put('/:id', authenticate, authorizeAdmin, validate(planValidator.updatePlan), planController.update);

/**
 * @swagger
 * /api/plans/{id}:
 *   delete:
 *     tags: [Plans]
 *     summary: Delete a plan (Admin only, soft delete)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Plan deleted
 */
router.delete('/:id', authenticate, authorizeAdmin, validate(planValidator.getPlan), planController.remove);

module.exports = router;
