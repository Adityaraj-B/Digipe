const swaggerJsdoc = require('swagger-jsdoc');
const path = require('path');
const env = require('./env');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'DigiPe Insurance Marketplace API',
      version: '1.0.0',
      description: 'Complete REST API documentation for the Dynamic Insurance Marketplace platform. Browse insurance products, purchase plans, manage policies, and file claims.',
      contact: {
        name: 'DigiPe API Support',
      },
      license: {
        name: 'ISC',
      },
    },
    servers: [
      {
        url: 'https://api.digipe.in',
        description: 'Production Server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Enter your JWT token obtained from /api/auth/verify-otp',
        },
      },
    },
    tags: [
      { name: 'Auth', description: 'Authentication endpoints (OTP + JWT)' },
      { name: 'Categories', description: 'Insurance category management' },
      { name: 'Products', description: 'Insurance product management' },
      { name: 'Plans', description: 'Insurance plan management' },
      { name: 'Product Fields', description: 'Dynamic form field management' },
      { name: 'Applications', description: 'Insurance application management' },
      
      { name: 'Orders', description: 'Order management' },
      { name: 'Payments', description: 'Payment management' },
      { name: 'Policies', description: 'Insurance policy management' },
      { name: 'Claims', description: 'Insurance claim management' },
      { name: 'Documents', description: 'Document upload and management' },
    ],
  },
  apis: [
    './src/routes/*.js',
    './src/docs/*.js',
  ],
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = swaggerSpec;
