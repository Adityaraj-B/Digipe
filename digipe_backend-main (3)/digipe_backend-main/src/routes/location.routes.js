const express = require('express');
const router = express.Router();
const { authenticate } = require('../middlewares/auth.middleware');
const locationController = require('../controllers/location.controller');

/**
 * @route   PUT /api/users/location
 * @desc    Update authenticated user's GPS location
 * @access  Private
 * @body    { latitude: number, longitude: number }
 */
router.put('/location', authenticate, locationController.updateLocation);

/**
 * @route   POST /api/users/push-token
 * @desc    Register an FCM push notification token
 * @access  Private
 * @body    { token: string, platform?: 'web' | 'android' | 'ios' }
 */
router.post('/push-token', authenticate, locationController.registerPushToken);

/**
 * @route   DELETE /api/users/push-token
 * @desc    Remove an FCM push notification token
 * @access  Private
 * @body    { token: string }
 */
router.delete('/push-token', authenticate, locationController.removePushToken);

module.exports = router;
