# DigiPe Insurance Marketplace Backend

Welcome to the backend API of the **DigiPe Insurance Marketplace** platform. This is a dynamic, high-performance RESTful API built with Node.js, Express.js, and MongoDB. It supports customizable insurance products, category management, dynamic application forms with custom fields, checkout/cart workflows, order tracking, payment processing, policy issuance, and a robust claim filing system with secure document uploads.

---

## 🚀 Key Features

*   **Secure OTP Authentication**: Passwordless authentication using Surefy Auth (WhatsApp-based OTP) and stateful JSON Web Token (JWT) user sessions.
*   **Dynamic Product Schema**: Supports dynamic fields for insurance products, allowing administrators to define custom form fields (with validation rules) required for different insurance types.
*   **Complete Shopping Cart & Order Flow**: Standard checkout process with cart persistence, orders, and payments.
*   **Policy & Claims Management**: Handle policy lifecycles and file claims with document attachments.
*   **Swagger API Documentation**: Automated API documentation generated via Swagger JSDoc and accessible through an interactive UI.
*   **Security & Protection**: Configured with security middlewares including Helmet (security headers), CORS, Mongo Sanitize (NoSQL injection defense), XSS-Clean (cross-site scripting protection), and rate limiting.
*   **Centralized Logging**: Custom request logging and error handling utilizing Winston and Morgan.

---

## 🛠️ Tech Stack

*   **Runtime**: [Node.js](https://nodejs.org/) (v16+ or v18+ recommended)
*   **Framework**: [Express.js](https://expressjs.com/)
*   **Database**: [MongoDB](https://www.mongodb.com/) via [Mongoose ODM](https://mongoosejs.com/)
*   **Authentication**: [Surefy Auth (Digipe)](https://auth.surefy.co) & [jsonwebtoken](https://github.com/auth0/node-jsonwebtoken)
*   **File Uploads**: [Cloudinary SDK](https://cloudinary.com/) & [Multer](https://github.com/expressjs/multer)
*   **Validation**: [Joi](https://joi.dev/)
*   **Documentation**: [Swagger UI Express](https://github.com/scottie198/swagger-ui-express)
*   **Logging**: [Winston](https://github.com/winstonjs/winston) & [Morgan](https://github.com/expressjs/morgan)

---

## 📋 Prerequisites

Before setting up and running the application, make sure you have installed:

1.  **Node.js** (v16.x or higher)
2.  **npm** (Node Package Manager)
3.  **MongoDB** (Local instance running on `mongodb://localhost:27017` or a MongoDB Atlas connection string)
4.  Accounts and credentials for:
    *   **Surefy Auth** (API Key for the Digipe product)
    *   **Cloudinary** (Cloud Name, API Key, and API Secret)

---

## ⚙️ Installation & Setup

Follow these steps to set up the project locally:

### 1. Navigate to the Backend Directory
If you are at the repository root, go to the backend folder:
```bash
cd backend
```

### 2. Install Dependencies
Install all package dependencies defined in `package.json`:
```bash
npm install
```

### 3. Configure Environment Variables
Copy the `.env.example` template to create your `.env` file:
```bash
cp .env.example .env
```

Open the newly created `.env` file and populate it with your configuration credentials:
```env
# SERVER CONFIG
NODE_ENV=development
PORT=5000

# MONGODB CONFIG
MONGODB_URI=mongodb://localhost:27017/digipe_insurance

# JWT CONFIG
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRES_IN=24h

# SUREFY AUTH CONFIG (Required for OTP authentication)
SUREFY_AUTH_BASE_URL=https://auth.surefy.co/api/v1
SUREFY_API_KEY=YOUR-SUREFY-API-KEY

# CLOUDINARY CONFIG (Required for upload routes/documents)
CLOUDINARY_CLOUD_NAME=your-cloudinary-cloud-name
CLOUDINARY_API_KEY=your-cloudinary-api-key
CLOUDINARY_API_SECRET=your-cloudinary-api-secret

# CORS & RATE LIMITING
CORS_ORIGIN=http://localhost:3000
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100
```

> [!NOTE]
> Ensure MongoDB is running before initiating seeding or starting the server. If using MongoDB Atlas, replace the `MONGODB_URI` with your connection string.

### 4. Seed the Database
Seed the database with the default Super Admin user account:
```bash
npm run db:seed
```
This script will connect to your MongoDB database and create a default Super Admin user with:
*   **Name**: `Super Admin`
*   **Mobile Number**: `+918218128937`
*   **Role**: `admin`

### 5. Run the Application

#### Development Mode (with hot-reloading)
Starts the server using `nodemon` which watches for file changes:
```bash
npm run dev
```

#### Production Mode
Starts the server using standard Node:
```bash
npm start
```

You should see log messages in your terminal confirming database connection and server initialization:
```text
[info]: MongoDB Connected: localhost:27017/digipe_insurance
[info]: Server is running on port 5000 in development mode
```

---

## 📂 Folder Structure

The project follows a clean layered architecture separating route parsing, input validation, business logic, and database operations.

```text
backend/
├── src/
│   ├── config/             # Configuration files (DB, Cloudinary, Swagger, env, logger)
│   ├── constants/          # Application-wide constants & status messages
│   ├── controllers/        # Express Route Handlers (interfaces with request and sends response)
│   ├── docs/               # Swagger schemas & Swagger API doc components
│   ├── middlewares/        # Custom middlewares (auth, error-handler, logger, validator)
│   ├── models/             # Mongoose schemas & Database models
│   ├── repositories/       # Data access layer (encapsulates Mongoose queries)
│   ├── routes/             # API Router definitions
│   ├── services/           # Business logic layer (computes, processes, calls APIs/Repos)
│   ├── utils/              # Helper functions, error handlers, and pagination helpers
│   ├── validators/         # Request body validation schemas (Joi)
│   ├── app.js              # Express app setup and middleware configuration
│   ├── seed.js             # Seeding script for DB defaults
│   └── server.js           # App server entry point
├── .env.example            # Environment variables template
├── .gitignore              # Files to ignore in Git
├── package.json            # Node project configuration & dependency list
└── README.md               # Setup and development instructions
```

---

## 📖 API Documentation

This backend features interactive Swagger API documentation. 

Once the server is running, navigate to:
*   **Swagger UI**: [http://localhost:5000/api-docs](http://localhost:5000/api-docs)
*   **Swagger JSON Specs**: [http://localhost:5000/api-docs.json](http://localhost:5000/api-docs.json)

### 🔐 Authenticating in Swagger
1. Request an OTP using the `/api/auth/send-otp` endpoint (using any valid mobile number with country code, e.g., `+91XXXXXXXXXX`).
2. Verify the OTP using the `/api/auth/verify-otp` endpoint (input the 6-digit code received via WhatsApp).
3. Copy the `token` string returned in the response.
4. Click the **Authorize** button at the top of the Swagger UI page.
5. Enter the token in the following format: `Bearer <your_token>` and click Authorize.

---

## 🔐 Environment Variables Reference

| Variable Name | Description | Default | Required |
| :--- | :--- | :--- | :--- |
| `NODE_ENV` | Running environment mode (`development`, `production`, `test`) | `development` | Yes |
| `PORT` | The port the backend server listens on | `5000` | Yes |
| `MONGODB_URI` | Connection URI for the MongoDB Database | `mongodb://localhost:27017/digipe_insurance` | Yes |
| `JWT_SECRET` | Secret key used for signing JWT login tokens | - | Yes (Change for Production) |
| `JWT_EXPIRES_IN` | Token expiration duration (e.g., `24h`, `7d`) | `24h` | Yes |
| `SUREFY_AUTH_BASE_URL` | Base URL for Surefy Auth API | `https://auth.surefy.co/api/v1` | No |
| `SUREFY_API_KEY` | API Key for Surefy Auth (Digipe product) | - | Yes |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary storage account name | - | Yes |
| `CLOUDINARY_API_KEY` | Cloudinary API authorization key | - | Yes |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret credential | - | Yes |
| `CORS_ORIGIN` | Allowed domains for Cross-Origin Resource Sharing | `*` | No |
| `RATE_LIMIT_WINDOW_MS`| Rate limiter time window in milliseconds | `900000` (15 mins) | No |
| `RATE_LIMIT_MAX` | Max number of requests allowed per client in window | `100` | No |

---

## 🔍 Verification & Health Check

Verify the API is running correctly by calling the health check endpoint:

```bash
curl http://localhost:5000/health
```

Expected Response:
```json
{
  "success": true,
  "message": "DigiPe Insurance Marketplace API is running",
  "environment": "development",
  "timestamp": "2026-06-01T17:05:00.000Z"
}
```
