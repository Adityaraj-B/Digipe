const { Cashfree, CFEnvironment } = require('cashfree-pg');
const env = require('./env');
const logger = require('./logger');

/**
 * Initialize Cashfree Payment Gateway SDK.
 * Creates a configured Cashfree instance using credentials from environment variables.
 */
const cashfreeClient = new Cashfree('2023-08-01');

cashfreeClient.XClientId = env.cashfree.clientId;
cashfreeClient.XClientSecret = env.cashfree.clientSecret;
cashfreeClient.XEnvironment =
  env.cashfree.environment === 'production'
    ? CFEnvironment.PRODUCTION
    : CFEnvironment.SANDBOX;

logger.info(`Cashfree SDK initialized in ${env.cashfree.environment} mode`);

module.exports = { cashfreeClient };
