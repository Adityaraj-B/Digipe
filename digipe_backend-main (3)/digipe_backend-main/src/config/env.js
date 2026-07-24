const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '../../.env') });

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT, 10) || 5000,
  mongodbUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/digipe_insurance',
  jwt: {
    secret: process.env.JWT_SECRET || 'default_jwt_secret_change_in_production',
    expiresIn: process.env.JWT_EXPIRES_IN || '24h',
  },
  surefy: {
    baseUrl: process.env.SUREFY_AUTH_BASE_URL || 'https://auth.surefy.co/api/v1',
    apiKey: process.env.SUREFY_API_KEY,
  },
  cloudinary: {
    cloudName: process.env.CLOUDINARY_CLOUD_NAME,
    apiKey: process.env.CLOUDINARY_API_KEY,
    apiSecret: process.env.CLOUDINARY_API_SECRET,
  },
  corsOrigin: process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(',').map(s => s.trim())
    : 'https://app.digipe.com',
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 900000,
    max: parseInt(process.env.RATE_LIMIT_MAX, 10) || 100,
  },
  apiDomainName: process.env.API_DOMAIN_NAME || 'api.digipe.in',
  cashfree: {
    clientId: process.env.CASHFREE_CLIENT_ID,
    clientSecret: process.env.CASHFREE_CLIENT_SECRET,
    environment: process.env.CASHFREE_ENVIRONMENT || 'sandbox',
  },
  frontendSuccessUrl: process.env.FRONTEND_SUCCESS_URL || 'http://localhost:3000/payment/success',
  frontendFailureUrl: process.env.FRONTEND_FAILURE_URL || 'http://localhost:3000/payment/failure',
  hubble: {
    clientId: process.env.HUBBLE_CLIENT_ID,
    clientSecret: process.env.HUBBLE_CLIENT_SECRET,
    sdkBaseUrl: process.env.HUBBLE_SDK_BASE_URL || 'https://sdk.dev.myhubble.money/',
    ssoPrivateKeyPath: process.env.HUBBLE_SSO_PRIVATE_KEY_PATH || './keys/hubble_private_key.pem',
  },
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY
      ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
      : undefined,
  },
};

module.exports = env;
