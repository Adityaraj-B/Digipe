# Cashfree Payment Integration — Documentation

## Overview

This document describes the complete Cashfree Payment Gateway integration for the DigiPe Insurance Marketplace backend.

---

## 1. Payment Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        PAYMENT LIFECYCLE                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. Frontend calls  POST /api/payments  with { orderId }               │
│                          │                                              │
│  2. Backend validates order → creates Cashfree order                   │
│                          │                                              │
│  3. Backend returns { paymentSessionId, cashfreeOrderId }              │
│                          │                                              │
│  4. Frontend opens Cashfree Checkout using payment_session_id          │
│                          │                                              │
│  5. User completes payment on Cashfree checkout page                   │
│                          │                                              │
│  6. Cashfree sends webhook → POST /api/payments/webhook                │
│     Backend verifies signature → updates Payment + Order status        │
│     Generates insurance policies if SUCCESS                            │
│                          │                                              │
│  7. Frontend calls  GET /api/payments/status/:orderId                  │
│     Backend fetches latest status from Cashfree → returns result       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Files Modified

| File | Change |
|------|--------|
| `src/config/env.js` | Added `cashfree` config block and frontend URL settings |
| `src/config/cashfree.js` | **NEW** — Cashfree SDK initialization |
| `src/models/payment.model.js` | Added `cashfreeOrderId`, `paymentSessionId` fields |
| `src/repositories/payment.repository.js` | Added `findByCashfreeOrderId()` method |
| `src/constants/messages.js` | Added payment messages: `SESSION_CREATED`, `VERIFIED`, `WEBHOOK_RECEIVED`, `VERIFICATION_FAILED` |
| `src/services/payment.service.js` | Complete rewrite — Cashfree integration with `createPayment`, `verifyPayment`, `handleWebhook` |
| `src/controllers/payment.controller.js` | Added `verifyPayment`, `handleWebhook` controller methods |
| `src/validators/payment.validator.js` | Made `paymentMethod` optional, added `verifyPayment` validator |
| `src/routes/payment.routes.js` | Added `GET /status/:orderId` and `POST /webhook` routes |
| `.env` | Added Cashfree environment variables |
| `.env.example` | Added Cashfree placeholder variables |

---

## 3. API Endpoints

### 3.1 Create Payment Order

```
POST /api/payments
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "orderId": "6478a1b2c3d4e5f6a7b8c9d0"
}
```

> `paymentMethod` is optional. Cashfree handles payment method selection on the checkout page.

**Success Response (201):**
```json
{
  "success": true,
  "statusCode": 201,
  "message": "Payment session created successfully",
  "data": {
    "payment": {
      "_id": "6478a1b2c3d4e5f6a7b8c9d1",
      "order": "6478a1b2c3d4e5f6a7b8c9d0",
      "user": "6478a1b2c3d4e5f6a7b8c9d2",
      "amount": 5000,
      "transactionId": "TXN-A1B2C3D4E5F6",
      "cashfreeOrderId": "cf_ORD-A1B2C3D4_1717620000000",
      "paymentSessionId": "session_xxxxxxxxxxxxxxxxxxxx",
      "status": "PENDING",
      "createdAt": "2026-06-06T00:00:00.000Z"
    },
    "paymentSessionId": "session_xxxxxxxxxxxxxxxxxxxx",
    "cashfreeOrderId": "cf_ORD-A1B2C3D4_1717620000000"
  }
}
```

**Error Responses:**
| Status | Message |
|--------|---------|
| 404 | Order not found |
| 403 | You do not have permission to perform this action |
| 409 | Order has already been paid |
| 400 | Order has been cancelled |

---

### 3.2 Verify Payment Status

```
GET /api/payments/status/:orderId
Authorization: Bearer <token>
```

**Success Response (200):**
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Payment verified successfully",
  "data": {
    "_id": "6478a1b2c3d4e5f6a7b8c9d1",
    "order": {
      "_id": "6478a1b2c3d4e5f6a7b8c9d0",
      "orderNumber": "ORD-A1B2C3D4",
      "totalAmount": 5000,
      "status": "CONFIRMED",
      "paymentStatus": "PAID"
    },
    "amount": 5000,
    "status": "SUCCESS",
    "paidAt": "2026-06-06T00:05:00.000Z",
    "gatewayResponse": { "...cashfree payment details..." }
  }
}
```

---

### 3.3 Cashfree Webhook

```
POST /api/payments/webhook
No Authorization Required
```

> This endpoint is called directly by Cashfree servers. Signature verification is performed internally.

**Request Headers (sent by Cashfree):**
```
x-cashfree-timestamp: 1717620000
x-cashfree-signature: <signature>
Content-Type: application/json
```

**Request Body (sent by Cashfree):**
```json
{
  "type": "PAYMENT_SUCCESS_WEBHOOK",
  "data": {
    "order": {
      "order_id": "cf_ORD-A1B2C3D4_1717620000000",
      "order_amount": 5000,
      "order_currency": "INR",
      "order_status": "PAID"
    },
    "payment": {
      "cf_payment_id": 123456789,
      "payment_status": "SUCCESS",
      "payment_amount": 5000,
      "payment_currency": "INR",
      "payment_group": "UPI",
      "payment_method": {
        "upi": {
          "upi_id": "user@upi"
        }
      },
      "payment_time": "2026-06-06T00:05:00+05:30"
    }
  }
}
```

**Response (200):**
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Webhook processed successfully",
  "data": {
    "status": "processed",
    "orderId": "cf_ORD-A1B2C3D4_1717620000000"
  }
}
```

---

### 3.4 Get Payment by ID

```
GET /api/payments/:id
Authorization: Bearer <token>
```

---

### 3.5 Get Payment by Order

```
GET /api/payments/order/:orderId
Authorization: Bearer <token>
```

---

## 4. Cashfree Order Creation Flow

1. Frontend sends `POST /api/payments` with the internal `orderId`
2. Backend validates the order (ownership, not cancelled, not already paid)
3. **Idempotency check**: If a PENDING payment already exists for this order with a valid `paymentSessionId`, it is returned immediately without creating a duplicate
4. Backend fetches user details (name, phone, email) for Cashfree customer info
5. Backend calls `cashfreeClient.PGCreateOrder()` with:
   - `order_amount`: from internal order
   - `order_currency`: INR
   - `order_id`: unique ID format `cf_{orderNumber}_{timestamp}`
   - `customer_details`: from user profile
   - `order_meta.return_url`: `FRONTEND_SUCCESS_URL?order_id={order_id}`
6. Cashfree returns `cf_order_id` and `payment_session_id`
7. Backend creates a Payment record with `status: PENDING`
8. Response includes `paymentSessionId` for the frontend to open Cashfree Checkout

---

## 5. Webhook Flow

1. Cashfree sends a POST request to `/api/payments/webhook` after payment events
2. Backend extracts `x-cashfree-timestamp` and `x-cashfree-signature` headers
3. Signature is verified using `cashfreeClient.PGVerifyWebhookSignature()`
4. Webhook body is parsed to extract `order_id` and `payment_status`
5. Backend looks up the Payment record using `cashfreeOrderId`
6. **Idempotency**: If already processed as SUCCESS, returns `already_processed`
7. Based on `payment_status`:
   - **SUCCESS**: Payment → SUCCESS, Order → CONFIRMED/PAID, policies generated
   - **FAILED/CANCELLED**: Payment → FAILED, Order paymentStatus → FAILED
   - **Other**: Gateway response stored, no status change

---

## 6. Database Changes

### Payment Model — New Fields

| Field | Type | Description |
|-------|------|-------------|
| `cashfreeOrderId` | String (indexed) | Cashfree's order identifier (e.g., `cf_ORD-A1B2C3D4_1717620000000`) |
| `paymentSessionId` | String | Session ID for Cashfree Checkout widget |

### Payment Model — Modified Fields

| Field | Change |
|-------|--------|
| `transactionId` | Added `sparse: true` to allow null values |
| `paymentMethod` | Now optional (was required) — Cashfree provides method post-payment |
| `gatewayResponse` | Now stores Cashfree response object |

### Order Status Flow

```
PENDING (created) → CONFIRMED (payment success) → policies generated
PENDING (created) → paymentStatus: FAILED (payment failed)
```

---

## 7. Required Environment Variables

```env
# Cashfree credentials from the Cashfree dashboard
CASHFREE_CLIENT_ID=your_cashfree_app_id
CASHFREE_CLIENT_SECRET=your_cashfree_secret_key

# 'sandbox' for testing, 'production' for live
CASHFREE_ENVIRONMENT=sandbox

# Frontend redirect URLs after payment
FRONTEND_SUCCESS_URL=http://localhost:3000/payment/success
FRONTEND_FAILURE_URL=http://localhost:3000/payment/failure
```

---

## 8. How to Test Using Postman

See `PAYMENT_API_TESTING.md` for detailed step-by-step testing instructions.

### Quick Test:

1. **Login** → Get JWT token via `POST /api/auth/send-otp` + `POST /api/auth/verify-otp`
2. **Create Order** → `POST /api/orders` with approved application items
3. **Create Payment** → `POST /api/payments` with the orderId from step 2
4. **Open Checkout** → Use `paymentSessionId` in Cashfree JS SDK
5. **Verify** → `GET /api/payments/status/:orderId`

---

## 9. Sample Webhook Payload

### Payment Success

```json
{
  "type": "PAYMENT_SUCCESS_WEBHOOK",
  "version": "2022-09-01",
  "data": {
    "order": {
      "order_id": "cf_ORD-A1B2C3D4_1717620000000",
      "order_amount": 5000,
      "order_currency": "INR",
      "order_status": "PAID"
    },
    "payment": {
      "cf_payment_id": 123456789,
      "payment_status": "SUCCESS",
      "payment_amount": 5000,
      "payment_currency": "INR",
      "payment_group": "UPI",
      "payment_method": {
        "upi": {
          "upi_id": "user@upi"
        }
      },
      "payment_time": "2026-06-06T00:05:00+05:30",
      "bank_reference": "1234567890"
    },
    "customer_details": {
      "customer_id": "6478a1b2c3d4e5f6a7b8c9d2",
      "customer_name": "John Doe",
      "customer_email": "john@example.com",
      "customer_phone": "9876543210"
    }
  },
  "event_time": "2026-06-06T00:05:05+05:30"
}
```

### Payment Failed

```json
{
  "type": "PAYMENT_FAILED_WEBHOOK",
  "version": "2022-09-01",
  "data": {
    "order": {
      "order_id": "cf_ORD-A1B2C3D4_1717620000000",
      "order_amount": 5000,
      "order_currency": "INR",
      "order_status": "ACTIVE"
    },
    "payment": {
      "cf_payment_id": 123456790,
      "payment_status": "FAILED",
      "payment_amount": 5000,
      "payment_message": "Transaction declined by bank",
      "payment_group": "CREDIT_CARD"
    }
  }
}
```

---

## 10. Complete Payment Lifecycle

```
1. Customer browses products → submits application → gets approved
2. Customer creates order with approved applications
3. Customer initiates payment (POST /api/payments)
4. Backend creates Cashfree order → returns payment_session_id
5. Frontend opens Cashfree checkout with session ID
6. Customer completes payment (UPI / Card / Netbanking / Wallet)
7. Cashfree sends webhook to backend → updates payment & order status
8. If SUCCESS: policies are auto-generated for each order item
9. Customer redirected to success page → verifies via GET /api/payments/status/:orderId
10. Customer can view policies via GET /api/policies/my
```

---

## 11. Common Errors and Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| `Payment processing failed` | Cashfree API call failed | Check `CASHFREE_CLIENT_ID` and `CASHFREE_CLIENT_SECRET` in `.env` |
| `Invalid webhook signature` | Webhook signature mismatch | Ensure `CASHFREE_CLIENT_SECRET` matches the one configured in Cashfree dashboard |
| `Order not found` | Invalid orderId | Verify the orderId is a valid MongoDB ObjectId from `POST /api/orders` |
| `Order has already been paid` | Duplicate payment attempt | Order already has a successful payment — no action needed |
| `Order has been cancelled` | Cancelled order | Create a new order — cancelled orders cannot be paid |
| `You do not have permission` | User doesn't own the order | Ensure the JWT token belongs to the user who created the order |
| `Missing webhook signature` | Cashfree headers missing | Webhook endpoint expects `x-cashfree-timestamp` and `x-cashfree-signature` headers |
| `Payment verification failed` | Cashfree status API error | Check network connectivity and API credentials |

### Debug Tips:

- Check `logs/combined.log` for detailed request/response logging
- Check `logs/error.log` for error stack traces
- All Cashfree API responses are stored in `gatewayResponse` field of the Payment document
- Use Cashfree Sandbox dashboard to view order and payment status
