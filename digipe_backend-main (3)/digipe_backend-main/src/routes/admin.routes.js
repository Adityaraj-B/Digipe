const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { authorizeAdmin } = require('../middlewares/admin.middleware');
const validate = require('../middlewares/validation.middleware');

const adminOrderController = require('../controllers/adminOrder.controller');
const adminLoginController = require('../controllers/adminLogin.controller');
const adminPriceSettingsController = require('../controllers/adminPriceSettings.controller');
const consentController = require('../controllers/consent.controller');
const adminPriceSettingsValidator = require('../validators/adminPriceSettings.validator');
const consentValidator = require('../validators/consent.validator');

/**
 * @swagger
 * /api/admin/dashboard:
 *   get:
 *     tags: [Admin]
 *     summary: Retrieve admin dashboard metrics (Admin only)
 *     description: Returns product-scoped or global overview metrics, recent purchases, and pending claims.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: productId
 *         required: false
 *         schema:
 *           type: string
 *         description: Optional ID of the insurance product to scope metrics to.
 *     responses:
 *       200:
 *         description: Successfully fetched dashboard data
 *       400:
 *         description: Invalid parameters
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden (Admin only)
 *       404:
 *         description: Product not found
 */
router.get('/dashboard', authenticate, authorizeAdmin, adminController.getDashboard);

// =====================================================
// PRICE SETTINGS
// =====================================================

/**
 * @swagger
 * /api/admin/price-settings:
 *   get:
 *     tags: [Admin - Price Settings]
 *     summary: Get current price settings (Admin only)
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Current promotional discount and tax settings
 */
router.get('/price-settings', authenticate, authorizeAdmin, adminPriceSettingsController.getSettings);

/**
 * @swagger
 * /api/admin/price-settings/discount:
 *   put:
 *     tags: [Admin - Price Settings]
 *     summary: Update promotional discount (Admin only)
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [percentage, isActive]
 *             properties:
 *               percentage: { type: number, minimum: 0, maximum: 100 }
 *               isActive: { type: boolean }
 *     responses:
 *       200:
 *         description: Promotional discount updated
 */
router.put('/price-settings/discount', authenticate, authorizeAdmin, validate(adminPriceSettingsValidator.updatePromotionalDiscount), adminPriceSettingsController.updatePromotionalDiscount);

/**
 * @swagger
 * /api/admin/price-settings/tax:
 *   put:
 *     tags: [Admin - Price Settings]
 *     summary: Update tax / GST settings (Admin only)
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [gstPercentage]
 *             properties:
 *               gstPercentage: { type: number, minimum: 0, maximum: 100 }
 *     responses:
 *       200:
 *         description: Tax settings updated
 */
router.put('/price-settings/tax', authenticate, authorizeAdmin, validate(adminPriceSettingsValidator.updateTax), adminPriceSettingsController.updateTax);

// =====================================================
// ORDERS
// =====================================================

/**
 * @swagger
 * /api/admin/orders:
 *   get:
 *     tags: [Admin Orders]
 *     summary: Retrieve orders with pagination, search, and filters
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *       - in: query
 *         name: product
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Orders fetched successfully
 */
router.get('/orders', authenticate, authorizeAdmin, adminOrderController.getOrders);

/**
 * @swagger
 * /api/admin/orders/{id}:
 *   get:
 *     tags: [Admin Orders]
 *     summary: Get detailed order view (Admin only)
 *     description: Returns complete order data including customer details, plan details, verification documents, uploaded images/videos, and current status.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Order ID
 *     responses:
 *       200:
 *         description: Complete order details
 *       404:
 *         description: Order not found
 */
router.get('/orders/:id', authenticate, authorizeAdmin, adminOrderController.getOrderDetail);

/**
 * @swagger
 * /api/admin/orders/{id}/status:
 *   patch:
 *     tags: [Admin Orders]
 *     summary: Update order status
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               status:
 *                 type: string
 *     responses:
 *       200:
 *         description: Order status updated successfully
 */
router.patch('/orders/:id/status', authenticate, authorizeAdmin, adminOrderController.updateOrderStatus);

/**
 * @swagger
 * /api/admin/orders/{id}:
 *   delete:
 *     tags: [Admin Orders]
 *     summary: Delete an order (soft delete, Admin only)
 *     description: Soft-deletes a PENDING or CANCELLED order. Confirmed orders cannot be deleted. Associated pending payment records are cleaned up.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Order ID
 *     responses:
 *       200:
 *         description: Order deleted successfully
 *       400:
 *         description: Cannot delete confirmed order
 *       404:
 *         description: Order not found
 */
router.delete('/orders/:id', authenticate, authorizeAdmin, adminOrderController.deleteOrder);

// =====================================================
// CONSENT
// =====================================================

/**
 * @swagger
 * /api/admin/consents/{id}:
 *   get:
 *     tags: [Admin - Consent]
 *     summary: Get consent details for an application (Admin only)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Application ID
 *     responses:
 *       200:
 *         description: Consent details
 *       404:
 *         description: Consent not found
 */
router.get('/consents/:id', authenticate, authorizeAdmin, validate(consentValidator.getConsent), consentController.getConsent);

// =====================================================
// LOGIN LOGS
// =====================================================

/**
 * @swagger
 * /api/admin/logins:
 *   get:
 *     tags: [Admin]
 *     summary: Get paginated login audit trail (Admin only)
 *     description: Returns a paginated list of all login attempts (success and failure) with session IDs, timestamps, roles, and status.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 5
 *         description: Items per page
 *     responses:
 *       200:
 *         description: Login logs fetched successfully
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden (Admin only)
 */
router.get('/logins', authenticate, authorizeAdmin, adminLoginController.getLogins);

module.exports = router;
