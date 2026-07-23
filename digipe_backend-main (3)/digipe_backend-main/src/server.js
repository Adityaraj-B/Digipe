const app = require('./app');
const env = require('./config/env');
const logger = require('./config/logger');
const connectDatabase = require('./config/database');
const { seedAdmin } = require('./seed');
const { startCouponAlertCron, stopCouponAlertCron } = require('./scripts/couponAlertCron');

const startServer = async () => {
  try {
    // Connect to MongoDB
    await connectDatabase();

    // Seed admin user at start
    await seedAdmin();

    // Start scheduled jobs
    startCouponAlertCron();

    // Start Express server
    const server = app.listen(env.port, () => {
      logger.info(`=================================================`);
      logger.info(`DigiPe Insurance Marketplace API`);
      logger.info(`=================================================`);
      logger.info(`Environment : ${env.nodeEnv}`);
      logger.info(`Port        : ${env.port}`);
      logger.info(`API URL     : https://api.digipe.in/api`);
      logger.info(`Swagger     : https://api.digipe.in/api-docs`);
      logger.info(`Health      : https://api.digipe.in/health`);
      logger.info(`Hubble SDK  : GET /api/hubble/sdk-token`);
      logger.info(`Location    : PUT /api/users/location`);
      logger.info(`=================================================`);
    });

    // Graceful shutdown
    const gracefulShutdown = (signal) => {
      logger.info(`${signal} received. Shutting down gracefully...`);
      stopCouponAlertCron();
      server.close(() => {
        logger.info('HTTP server closed');
        process.exit(0);
      });

      // Force close after 10 seconds
      setTimeout(() => {
        logger.error('Could not close connections in time, forcefully shutting down');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    // Unhandled errors
    process.on('unhandledRejection', (reason) => {
      logger.error('Unhandled Promise Rejection:', reason);
    });

    process.on('uncaughtException', (error) => {
      logger.error('Uncaught Exception:', error);
      process.exit(1);
    });

  } catch (error) {
    logger.error(`Failed to start server: ${error.message}`);
    process.exit(1);
  }
};

startServer();

