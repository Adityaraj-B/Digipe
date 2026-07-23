const morgan = require('morgan');
const logger = require('../config/logger');

/**
 * Morgan HTTP request logger middleware integrated with Winston.
 * Logs all HTTP requests in combined format.
 */
const stream = {
  write: (message) => {
    logger.info(message.trim());
  },
};

const requestLogger = morgan(
  ':remote-addr :method :url :status :res[content-length] - :response-time ms',
  { stream }
);

module.exports = requestLogger;
