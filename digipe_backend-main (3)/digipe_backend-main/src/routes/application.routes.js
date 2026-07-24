const express = require('express');
const router = express.Router();
const applicationController = require('../controllers/application.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { authorizeAdmin } = require('../middlewares/admin.middleware');
const validate = require('../middlewares/validation.middleware');
const applicationValidator = require('../validators/application.validator');

/**
 * @swagger
 * /api/applications:
 *   post:
 *     tags: [Applications]
 *     summary: Submit an insurance application (Customer)
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [planId]
 *             properties:
 *               planId: { type: string, description: Insurance plan ID }
 *               fieldValues:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required: [productField, fieldName, fieldValue]
 *                   properties:
 *                     productField: { type: string, description: Product field ID }
 *                     fieldName: { type: string }
 *                     fieldValue: { description: "Can be string, number, boolean, or array" }
 *     responses:
 *       201:
 *         description: Application submitted
 *       409:
 *         description: Duplicate application for this plan
 */
router.post('/', authenticate, validate(applicationValidator.createApplication), applicationController.create);

/**
 * @swagger
 * /api/applications/my:
 *   get:
 *     tags: [Applications]
 *     summary: Get my applications (Customer)
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
 *         schema: { type: string, enum: [DRAFT, SUBMITTED, UNDER_REVIEW, APPROVED, REJECTED] }
 *     responses:
 *       200:
 *         description: My applications
 */
router.get('/my', authenticate, applicationController.getMyApplications);

/**
 * @swagger
 * /api/applications:
 *   get:
 *     tags: [Applications]
 *     summary: Get all applications (Admin only)
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
 *         description: All applications
 */
router.get('/', authenticate, authorizeAdmin, applicationController.getAll);

/**
 * @swagger
 * /api/applications/{id}:
 *   get:
 *     tags: [Applications]
 *     summary: Get application details
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Application details with field values
 */
router.get('/:id', authenticate, validate(applicationValidator.getApplication), applicationController.getById);

/**
 * @swagger
 * /api/applications/{id}/status:
 *   patch:
 *     tags: [Applications]
 *     summary: Update application status (Admin only)
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
 *             required: [status]
 *             properties:
 *               status: { type: string, enum: [DRAFT, SUBMITTED, UNDER_REVIEW, APPROVED, REJECTED] }
 *               remarks: { type: string }
 *     responses:
 *       200:
 *         description: Application status updated
 */
router.patch('/:id/status', authenticate, authorizeAdmin, validate(applicationValidator.updateApplicationStatus), applicationController.updateStatus);

// =====================================================
// CONSENT ENDPOINTS
// =====================================================

const consentController = require('../controllers/consent.controller');
const consentValidator = require('../validators/consent.validator');

/**
 * @swagger
 * /api/applications/{id}/consent:
 *   post:
 *     tags: [Applications]
 *     summary: Record user consent for an application (Customer)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *         description: Application ID
 *     responses:
 *       200:
 *         description: User consent recorded
 *       404:
 *         description: Consent record not found (application must be approved first)
 */
router.post('/:id/consent', authenticate, validate(consentValidator.recordUserConsent), consentController.recordUserConsent);

/**
 * @swagger
 * /api/applications/{id}/consent:
 *   get:
 *     tags: [Applications]
 *     summary: Get consent status for an application
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *         description: Application ID
 *     responses:
 *       200:
 *         description: Consent details
 *       404:
 *         description: Consent not found
 */
router.get('/:id/consent', authenticate, validate(consentValidator.getConsent), consentController.getConsent);

module.exports = router;
