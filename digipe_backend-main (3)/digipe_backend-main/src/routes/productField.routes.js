const express = require('express');
const router = express.Router();
const productFieldController = require('../controllers/productField.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { authorizeAdmin } = require('../middlewares/admin.middleware');
const validate = require('../middlewares/validation.middleware');
const productFieldValidator = require('../validators/productField.validator');

/**
 * @swagger
 * /api/product-fields/product/{productId}:
 *   get:
 *     tags: [Product Fields]
 *     summary: Get dynamic form fields for a product
 *     description: Public endpoint — returns all active fields with their options
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Product fields with options
 *       404:
 *         description: Product not found
 */
router.get('/product/:productId', validate(productFieldValidator.getByProduct), productFieldController.getByProduct);

/**
 * @swagger
 * /api/product-fields:
 *   post:
 *     tags: [Product Fields]
 *     summary: Create a dynamic field (Admin only)
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [product, fieldName, fieldLabel, fieldType]
 *             properties:
 *               product: { type: string }
 *               fieldName: { type: string }
 *               fieldLabel: { type: string }
 *               fieldType: { type: string, enum: [TEXT, NUMBER, EMAIL, DATE, SELECT, RADIO, CHECKBOX, TEXTAREA, FILE] }
 *               placeholder: { type: string }
 *               isRequired: { type: boolean }
 *               validationRules:
 *                 type: object
 *                 properties:
 *                   min: { type: number }
 *                   max: { type: number }
 *                   minLength: { type: integer }
 *                   maxLength: { type: integer }
 *                   pattern: { type: string }
 *               options:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     label: { type: string }
 *                     value: { type: string }
 *                     sortOrder: { type: integer }
 *               sortOrder: { type: integer }
 *     responses:
 *       201:
 *         description: Field created with options
 */
router.post('/', authenticate, authorizeAdmin, validate(productFieldValidator.createProductField), productFieldController.create);

/**
 * @swagger
 * /api/product-fields/{id}:
 *   put:
 *     tags: [Product Fields]
 *     summary: Update a dynamic field (Admin only)
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
 *               fieldName: { type: string }
 *               fieldLabel: { type: string }
 *               fieldType: { type: string }
 *               placeholder: { type: string }
 *               isRequired: { type: boolean }
 *               validationRules: { type: object }
 *               options: { type: array, items: { type: object } }
 *               sortOrder: { type: integer }
 *     responses:
 *       200:
 *         description: Field updated
 */
router.put('/:id', authenticate, authorizeAdmin, validate(productFieldValidator.updateProductField), productFieldController.update);

/**
 * @swagger
 * /api/product-fields/{id}:
 *   delete:
 *     tags: [Product Fields]
 *     summary: Delete a dynamic field (Admin only)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Field deleted
 */
router.delete('/:id', authenticate, authorizeAdmin, productFieldController.remove);

module.exports = router;
