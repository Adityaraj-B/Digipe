const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');
const swaggerUi = require('swagger-ui-express');

const env = require('./config/env');
const swaggerSpec = require('./config/swagger');
const requestLogger = require('./middlewares/requestLogger.middleware');
const { errorHandler, notFoundHandler } = require('./middlewares/error.middleware');
const routes = require('./routes');

const app = express();

// =====================================================
// PROXY TRUST (required behind nginx / Docker reverse proxy)
// =====================================================
// Enables express-rate-limit (and req.ip) to read the real
// client IP from X-Forwarded-For instead of the proxy's IP.
app.set('trust proxy', 1);

// =====================================================
// SECURITY MIDDLEWARES
// =====================================================

// Set security HTTP headers
app.use(helmet({
  contentSecurityPolicy: false,
}));

// Enable CORS
app.use(cors({
  origin: env.corsOrigin,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));

// Rate limiting — general
const generalLimiter = rateLimit({
  windowMs: env.rateLimit.windowMs,
  max: env.rateLimit.max,
  message: {
    success: false,
    statusCode: 429,
    message: 'Too many requests. Please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api', generalLimiter);

// Stricter rate limit for OTP endpoints
const otpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,
  message: {
    success: false,
    statusCode: 429,
    message: 'Too many OTP requests. Please try again after 15 minutes.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/auth/send-otp', otpLimiter);

// Sanitize data — prevent NoSQL injection
app.use(mongoSanitize());

// Prevent XSS attacks
app.use(xss());

// =====================================================
// BODY PARSERS
// =====================================================

app.use(express.json({
  limit: '10mb',
  verify: (req, _res, buf) => {
    // Preserve raw body for Cashfree webhook signature verification
    if (req.url === '/api/payments/webhook' || req.originalUrl === '/api/payments/webhook') {
      req.rawBody = buf.toString('utf8');
    }
  },
}));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// =====================================================
// LOGGING
// =====================================================

app.use(requestLogger);

// =====================================================
// SWAGGER DOCUMENTATION
// =====================================================

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  explorer: true,
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'DigiPe Insurance Marketplace API',
}));

// Expose swagger spec as JSON
app.get('/api-docs.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

// =====================================================
// HEALTH CHECK
// =====================================================

app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'DigiPe Insurance Marketplace API is running',
    environment: env.nodeEnv,
    timestamp: new Date().toISOString(),
  });
});

// =====================================================
// API ROUTES
// =====================================================

app.use('/api', routes);

// =====================================================
// ERROR HANDLING
// =====================================================

// Handle 404 — unmatched routes
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

module.exports = app;
