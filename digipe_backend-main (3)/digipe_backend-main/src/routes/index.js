const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
const categoryRoutes = require('./category.routes');
const productRoutes = require('./product.routes');
const planRoutes = require('./plan.routes');
const productFieldRoutes = require('./productField.routes');
const applicationRoutes = require('./application.routes');

const orderRoutes = require('./order.routes');
const paymentRoutes = require('./payment.routes');
const policyRoutes = require('./policy.routes');
const claimRoutes = require('./claim.routes');
const documentRoutes = require('./document.routes');
const adminRoutes = require('./admin.routes');

// ── Hubble & Location ─────────────────────────────────
const hubbleRoutes = require('./hubble.routes');
const hubbleWebhookRoutes = require('./hubbleWebhook.routes');
const locationRoutes = require('./location.routes');

router.use('/auth', authRoutes);
router.use('/categories', categoryRoutes);
router.use('/products', productRoutes);
router.use('/plans', planRoutes);
router.use('/product-fields', productFieldRoutes);
router.use('/applications', applicationRoutes);
router.use('/orders', orderRoutes);
router.use('/payments', paymentRoutes);
router.use('/policies', policyRoutes);
router.use('/claims', claimRoutes);
router.use('/documents', documentRoutes);
router.use('/admin', adminRoutes);

// ── Hubble & Location ─────────────────────────────────
router.use('/hubble', hubbleRoutes);
router.use('/hubble', hubbleWebhookRoutes);
router.use('/users', locationRoutes);

module.exports = router;
