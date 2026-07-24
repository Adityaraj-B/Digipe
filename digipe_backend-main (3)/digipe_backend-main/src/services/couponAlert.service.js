const User = require('../models/user.model');
const notificationService = require('./notification.service');
const locationService = require('./location.service');
const logger = require('../config/logger');

/**
 * Curated list of popular coupon deals by city.
 * In production, this would be fetched from Hubble's API or a CMS.
 * For now, we use a static list that rotates based on day of week.
 */
const COUPON_CATALOG = {
  _default: [
    {
      brand: 'Amazon',
      discount: 'Up to 10% off',
      description: 'Get extra savings on Amazon Gift Cards',
      imageUrl: 'https://cdn.myhubble.money/amazon-logo.png',
      category: 'shopping',
    },
    {
      brand: 'Swiggy',
      discount: 'Flat ₹150 off',
      description: 'Save on your next food order with Swiggy vouchers',
      imageUrl: 'https://cdn.myhubble.money/swiggy-logo.png',
      category: 'food',
    },
    {
      brand: 'Flipkart',
      discount: 'Up to 8% off',
      description: 'Shop smarter with Flipkart Gift Cards',
      imageUrl: 'https://cdn.myhubble.money/flipkart-logo.png',
      category: 'shopping',
    },
    {
      brand: 'Zomato',
      discount: 'Flat ₹100 off',
      description: 'Enjoy discounts on Zomato orders',
      imageUrl: 'https://cdn.myhubble.money/zomato-logo.png',
      category: 'food',
    },
    {
      brand: 'Myntra',
      discount: 'Up to 12% off',
      description: 'Fashion deals with Myntra Gift Cards',
      imageUrl: 'https://cdn.myhubble.money/myntra-logo.png',
      category: 'fashion',
    },
    {
      brand: 'BigBasket',
      discount: 'Flat 5% off',
      description: 'Save on groceries with BigBasket vouchers',
      imageUrl: 'https://cdn.myhubble.money/bigbasket-logo.png',
      category: 'groceries',
    },
    {
      brand: 'BookMyShow',
      discount: 'Up to ₹200 off',
      description: 'Movie & event tickets at a discount',
      imageUrl: 'https://cdn.myhubble.money/bms-logo.png',
      category: 'entertainment',
    },
  ],
  Mumbai: [
    {
      brand: 'Uber',
      discount: 'Flat ₹100 off',
      description: 'Save on rides across Mumbai',
      imageUrl: 'https://cdn.myhubble.money/uber-logo.png',
      category: 'travel',
    },
  ],
  Delhi: [
    {
      brand: 'Ola',
      discount: 'Flat ₹80 off',
      description: 'Ride deals in Delhi NCR',
      imageUrl: 'https://cdn.myhubble.money/ola-logo.png',
      category: 'travel',
    },
  ],
  Bangalore: [
    {
      brand: 'Dunzo',
      discount: 'Flat ₹50 off',
      description: 'Quick delivery deals in Bangalore',
      imageUrl: 'https://cdn.myhubble.money/dunzo-logo.png',
      category: 'delivery',
    },
  ],
};

/**
 * Get trending coupons for a city.
 * Combines city-specific deals with the default catalog.
 * Rotates selection based on day of week to keep it fresh.
 *
 * @param {string|null} city - City name (null for default)
 * @returns {Array} Array of coupon objects
 */
const getTrendingCoupons = (city = null) => {
  const defaultCoupons = COUPON_CATALOG._default;
  const cityCoupons = city ? (COUPON_CATALOG[city] || []) : [];
  const allCoupons = [...cityCoupons, ...defaultCoupons];

  // Rotate based on day of week so users don't see the same deals every day
  const dayOfWeek = new Date().getDay();
  const startIdx = dayOfWeek % allCoupons.length;

  // Pick 2-3 deals to feature in the notification
  const featured = [];
  for (let i = 0; i < 3 && i < allCoupons.length; i++) {
    featured.push(allCoupons[(startIdx + i) % allCoupons.length]);
  }

  return featured;
};

/**
 * Build a push notification payload from coupon data.
 *
 * @param {Array} coupons - Array of coupon objects
 * @param {string|null} city - City name for personalization
 * @returns {{ title: string, body: string, data: Object }}
 */
const buildCouponNotificationPayload = (coupons, city = null) => {
  if (!coupons || coupons.length === 0) {
    return null;
  }

  const topCoupon = coupons[0];
  const cityText = city ? ` in ${city}` : '';

  return {
    title: `🎉 ${topCoupon.brand}: ${topCoupon.discount}${cityText}!`,
    body: coupons.length > 1
      ? `${topCoupon.description} + ${coupons.length - 1} more deals waiting for you!`
      : topCoupon.description,
    data: {
      type: 'coupon_alert',
      brand: topCoupon.brand,
      discount: topCoupon.discount,
      deepLink: '/hubble-store', // Frontend route to open Hubble SDK
      city: city || '',
    },
    imageUrl: topCoupon.imageUrl || null,
  };
};

/**
 * Send coupon alert notifications to all eligible users in a specific city.
 *
 * @param {string} city - City name
 * @returns {{ sent: number, failed: number }}
 */
const sendCouponAlertsForCity = async (city) => {
  const users = await locationService.getUsersInCity(city);

  if (users.length === 0) {
    logger.debug(`No eligible users in ${city} for coupon alerts`);
    return { sent: 0, failed: 0 };
  }

  const coupons = getTrendingCoupons(city);
  const payload = buildCouponNotificationPayload(coupons, city);

  if (!payload) {
    logger.debug(`No coupons available for ${city}`);
    return { sent: 0, failed: 0 };
  }

  // Collect all FCM tokens from users in this city
  const allTokens = [];
  users.forEach((user) => {
    user.pushTokens.forEach((pt) => {
      allTokens.push(pt.token);
    });
  });

  if (allTokens.length === 0) {
    logger.debug(`No push tokens for users in ${city}`);
    return { sent: 0, failed: 0 };
  }

  const result = await notificationService.sendToMultipleDevices(allTokens, payload);

  // Clean up invalid tokens
  if (result.invalidTokens.length > 0) {
    for (const invalidToken of result.invalidTokens) {
      try {
        const user = users.find((u) =>
          u.pushTokens.some((pt) => pt.token === invalidToken)
        );
        if (user) {
          await locationService.removePushToken(user._id, invalidToken);
        }
      } catch (error) {
        logger.warn(`Failed to remove invalid token: ${error.message}`);
      }
    }
  }

  logger.info(`Coupon alerts for ${city}: ${result.successCount} sent, ${result.failureCount} failed`);
  return { sent: result.successCount, failed: result.failureCount };
};

/**
 * Run the coupon alert job across all cities with eligible users.
 * This is called by the cron scheduler.
 */
const runCouponAlertJob = async () => {
  logger.info('🔔 Starting coupon alert cron job...');

  try {
    // Get all distinct cities with users
    const cities = await User.distinct('location.city', {
      'location.city': { $ne: null },
      'notificationPreferences.coupons': true,
      'pushTokens.0': { $exists: true },
      isActive: true,
      isDeleted: false,
    });

    logger.info(`Found ${cities.length} cities with eligible users: ${cities.join(', ')}`);

    let totalSent = 0;
    let totalFailed = 0;

    for (const city of cities) {
      const result = await sendCouponAlertsForCity(city);
      totalSent += result.sent;
      totalFailed += result.failed;
    }

    // Also send to users without a city (general coupons)
    const usersWithoutCity = await User.find({
      $or: [{ 'location.city': null }, { 'location.city': { $exists: false } }],
      'notificationPreferences.coupons': true,
      'pushTokens.0': { $exists: true },
      isActive: true,
      isDeleted: false,
    }).select('_id pushTokens');

    if (usersWithoutCity.length > 0) {
      const tokens = [];
      usersWithoutCity.forEach((u) => u.pushTokens.forEach((pt) => tokens.push(pt.token)));

      if (tokens.length > 0) {
        const coupons = getTrendingCoupons(null);
        const payload = buildCouponNotificationPayload(coupons, null);
        if (payload) {
          const result = await notificationService.sendToMultipleDevices(tokens, payload);
          totalSent += result.successCount;
          totalFailed += result.failureCount;
        }
      }
    }

    logger.info(`🔔 Coupon alert job complete: ${totalSent} sent, ${totalFailed} failed across ${cities.length} cities`);
    return { totalSent, totalFailed, cities: cities.length };
  } catch (error) {
    logger.error(`Coupon alert job failed: ${error.message}`);
    throw error;
  }
};

module.exports = {
  getTrendingCoupons,
  buildCouponNotificationPayload,
  sendCouponAlertsForCity,
  runCouponAlertJob,
};
