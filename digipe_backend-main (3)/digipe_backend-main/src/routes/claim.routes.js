const express = require('express');
const router = express.Router();
const claimController = require('../controllers/claim.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { authorizeAdmin } = require('../middlewares/admin.middleware');
const validate = require('../middlewares/validation.middleware');
const claimValidator = require('../validators/claim.validator');

/**
 * @swagger
 * /api/claims:
 *   post:
 *     tags: [Claims]
 *     summary: Submit a claim (Customer)
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [policyId, description, claimAmount]
 *             properties:
 *               policyId: { type: string, description: Active policy ID }
 *               description: { type: string }
 *               claimAmount: { type: number }
 *     responses:
 *       201:
 *         description: Claim submitted
 *       400:
 *         description: Policy not active
 *       409:
 *         description: Active claim already exists for this policy
 */
router.post('/', authenticate, validate(claimValidator.createClaim), claimController.create);

/**
 * @swagger
 * /api/claims/my:
 *   get:
 *     tags: [Claims]
 *     summary: Get my claims (Customer)
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
 *     responses:
 *       200:
 *         description: My claims
 */
router.get('/my', authenticate, claimController.getMyClaims);

/**
 * @swagger
 * /api/claims:
 *   get:
 *     tags: [Claims]
 *     summary: Get all claims (Admin only)
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
 *         description: All claims
 */
router.get('/', authenticate, authorizeAdmin, claimController.getAll);

/**
 * @swagger
 * /api/claims/{id}:
 *   get:
 *     tags: [Claims]
 *     summary: Get claim details
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Claim details with documents
 */
router.get('/:id', authenticate, validate(claimValidator.getClaim), claimController.getById);

/**
 * @swagger
 * /api/claims/{id}/documents:
 *   post:
 *     tags: [Claims]
 *     summary: Add a document to a claim (Customer)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *         description: Claim ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [documentId]
 *             properties:
 *               documentId: { type: string, description: Uploaded document ID }
 *               documentType: { type: string, enum: [MEDICAL_REPORT, POLICE_REPORT, ID_PROOF, ADDRESS_PROOF, INCOME_PROOF, CLAIM_FORM, PHOTO, OTHER] }
 *     responses:
 *       200:
 *         description: Document added to claim
 */
router.post('/:id/documents', authenticate, validate(claimValidator.addClaimDocument), claimController.addDocument);

/**
 * @swagger
 * /api/claims/{id}/status:
 *   patch:
 *     tags: [Claims]
 *     summary: Update claim status (Admin only)
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
 *               status: { type: string, enum: [SUBMITTED, UNDER_REVIEW, APPROVED, REJECTED, SETTLED] }
 *               remarks: { type: string }
 *               settledAmount: { type: number, description: Required when status is SETTLED }
 *     responses:
 *       200:
 *         description: Claim status updated
 */
router.patch('/:id/status', authenticate, authorizeAdmin, validate(claimValidator.updateClaimStatus), claimController.updateStatus);

module.exports = router;
