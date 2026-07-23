const cron = require('node-cron');
const logger = require('../config/logger');
const couponAlertService = require('../services/couponAlert.service');

/**
 * Coupon Alert Cron Job
 * Sends location-based coupon notifications to users.
 *
 * Schedule: Every day at 10:00 AM and 6:00 PM IST
 * (These are peak engagement times for coupon/deal notifications)
 *
 * Cron expression: '30 4,12 * * *' (UTC = IST - 5:30)
 * - 4:30 UTC = 10:00 AM IST
 * - 12:30 UTC = 6:00 PM IST
 */

let couponAlertJob = null;

const startCouponAlertCron = () => {
  // Run at 10:00 AM and 6:00 PM IST (4:30 AM and 12:30 PM UTC)
  couponAlertJob = cron.schedule('30 4,12 * * *', async () => {
    logger.info('⏰ Coupon alert cron triggered');

    try {
      const result = await couponAlertService.runCouponAlertJob();
      logger.info(`⏰ Cron result: ${JSON.stringify(result)}`);
    } catch (error) {
      logger.error(`⏰ Coupon alert cron failed: ${error.message}`);
    }
  }, {
    timezone: 'Asia/Kolkata',
  });

  // Also schedule with IST timezone directly if node-cron supports it
  // Fallback: use the UTC-based schedule above

  logger.info('📅 Coupon alert cron job scheduled (10:00 AM & 6:00 PM IST daily)');
};

const stopCouponAlertCron = () => {
  if (couponAlertJob) {
    couponAlertJob.stop();
    logger.info('📅 Coupon alert cron job stopped');
  }
};

module.exports = {
  startCouponAlertCron,
  stopCouponAlertCron,
};
