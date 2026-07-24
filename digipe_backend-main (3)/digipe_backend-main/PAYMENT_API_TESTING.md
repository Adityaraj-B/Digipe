# Cashfree Payment API — Testing Guide

Step-by-step guide to test the complete Cashfree payment integration using Postman or any HTTP client.

---

## Prerequisites

- Node.js installed
- MongoDB running (local or Atlas)
- Cashfree sandbox credentials configured in `.env`
- A registered user with a JWT token
- An approved insurance application

---

## Step 1: Start the Server

```bash
cd backend
npm install
npm run dev
```

Expected output:
```
Server running on port 3000 in development mode
Connected to MongoDB
Cashfree SDK initialized in sandbox mode
```

---

## Step 2: Create an Order

Before creating a payment, you need an order. This requires an approved application.

### Endpoint

```
POST http://localhost:3000/api/orders
```

### Headers

```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

### Sample Request Body

```json
{
  "items": [
    {
      "planId": "YOUR_PLAN_ID",
      "applicationId": "YOUR_APPROVED_APPLICATION_ID"
    }
  ]
}
```

### Expected Response (201)

```json
{
  "success": true,
  "statusCode": 201,
  "message": "Order created successfully",
  "data": {
    "_id": "6478a1b2c3d4e5f6a7b8c9d0",
    "orderNumber": "ORD-A1B2C3D4",
    "totalAmount": 5000,
    "status": "PENDING",
    "paymentStatus": "PENDING",
    "user": { ... },
    "items": [ ... ]
  }
}
```

> **Save the `_id` from the response.** You'll need it for the next step.

---

## Step 3: Create Payment Order (Get `payment_session_id`)

### Endpoint

```
POST http://localhost:3000/api/payments
```

### Headers

```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

### Sample Request Body

```json
{
  "orderId": "6478a1b2c3d4e5f6a7b8c9d0"
}
```

> `paymentMethod` is optional. Cashfree handles method selection.

### Expected Response (201)

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

### Idempotency Test

Send the **same request again** with the same `orderId`. You should receive the **same `paymentSessionId`** without a duplicate being created.

---

## Step 4: Open Cashfree Checkout

Use the `paymentSessionId` from Step 3 to open Cashfree Checkout on the frontend.

### Frontend JavaScript (Drop-in Checkout)

```html
<script src="https://sdk.cashfree.com/js/v3/cashfree.js"></script>
<script>
  const cashfree = Cashfree({ mode: "sandbox" }); // or "production"

  document.getElementById("pay-button").addEventListener("click", () => {
    cashfree.checkout({
      paymentSessionId: "session_xxxxxxxxxxxxxxxxxxxx", // from Step 3
      redirectTarget: "_self", // or "_blank"
    });
  });
</script>
```

### In Sandbox Mode

Use these test credentials on the Cashfree checkout page:

| Method | Details |
|--------|---------|
| **UPI** | Use any UPI ID (e.g., `success@upi` for success, `failure@upi` for failure) |
| **Card** | Card: `4111 1111 1111 1111`, Expiry: any future date, CVV: `123` |
| **Netbanking** | Select any bank, no actual login required |

---

## Step 5: Verify Payment Status

After the user completes (or abandons) the payment on Cashfree, call this endpoint to get the latest status.

### Endpoint

```
GET http://localhost:3000/api/payments/status/6478a1b2c3d4e5f6a7b8c9d0
```

> Replace `6478a1b2c3d4e5f6a7b8c9d0` with your internal orderId.

### Headers

```
Authorization: Bearer <your_jwt_token>
```

### Expected Response — Success (200)

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Payment verified successfully",
  "data": {
    "_id": "6478a1b2c3d4e5f6a7b8c9d1",
    "order": {
      "orderNumber": "ORD-A1B2C3D4",
      "totalAmount": 5000,
      "status": "CONFIRMED",
      "paymentStatus": "PAID"
    },
    "status": "SUCCESS",
    "paidAt": "2026-06-06T00:05:00.000Z",
    "gatewayResponse": { ... }
  }
}
```

### Expected Response — Pending (200)

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Payment verified successfully",
  "data": {
    "status": "PENDING",
    "paidAt": null
  }
}
```

---

## Step 6: Test Webhook Locally

Cashfree sends webhooks to your server's public URL. For local testing, use a tunnel.

### Option A: Using ngrok

```bash
# Install ngrok if not installed
npm install -g ngrok

# Start tunnel
ngrok http 3000
```

Copy the HTTPS URL (e.g., `https://abc123.ngrok.io`) and configure it in your Cashfree Dashboard:

1. Go to **Cashfree Dashboard** → **Developers** → **Webhooks**
2. Set webhook URL: `https://abc123.ngrok.io/api/payments/webhook`
3. Select events: `PAYMENT_SUCCESS_WEBHOOK`, `PAYMENT_FAILED_WEBHOOK`

### Option B: Manual Webhook Simulation

> **Note:** For manual testing without signature verification, you can temporarily comment out the signature check in `payment.service.js` → `handleWebhook()`.

```
POST http://localhost:3000/api/payments/webhook
Content-Type: application/json
x-cashfree-timestamp: 1717620000
x-cashfree-signature: test_signature
```

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
      "payment_time": "2026-06-06T00:05:00+05:30"
    }
  }
}
```

---

## Step 7: Verify Database Updates

### Check Payment Document

```bash
# Using MongoDB shell or Compass
db.payments.findOne({ order: ObjectId("YOUR_ORDER_ID") })
```

**Expected fields after successful payment:**

| Field | Value |
|-------|-------|
| `status` | `SUCCESS` |
| `cashfreeOrderId` | `cf_ORD-XXXXX_XXXXX` |
| `paymentSessionId` | `session_xxxx` |
| `gatewayResponse` | Full Cashfree response object |
| `paidAt` | Timestamp |
| `transactionId` | `TXN-XXXXXXXXXXXX` |

### Check Order Document

```bash
db.orders.findOne({ _id: ObjectId("YOUR_ORDER_ID") })
```

**Expected after success:**

| Field | Value |
|-------|-------|
| `status` | `CONFIRMED` |
| `paymentStatus` | `PAID` |

**Expected after failure:**

| Field | Value |
|-------|-------|
| `status` | `PENDING` |
| `paymentStatus` | `FAILED` |

### Check Policies Generated

```bash
db.policies.find({ order: ObjectId("YOUR_ORDER_ID") })
```

**Expected:** One policy per order item, each with:
- `policyNumber`: `POL-XXXXXXXX`
- `startDate`: current date
- `endDate`: start date + plan duration

---

## Step 8: Expected Success Flow

```
1. POST /api/payments → 201 (payment_session_id returned)
2. User completes payment on Cashfree checkout → SUCCESS
3. Cashfree sends webhook → POST /api/payments/webhook → 200
4. GET /api/payments/status/:orderId → 200 (status: SUCCESS)
5. Database: Payment.status = SUCCESS, Order.status = CONFIRMED
6. Policies auto-generated for each order item
```

### Verify the complete flow:

1. ✅ Payment record created with `PENDING` status
2. ✅ Cashfree order created with unique `cashfreeOrderId`
3. ✅ `payment_session_id` returned to frontend
4. ✅ After payment: webhook updates Payment to `SUCCESS`
5. ✅ Order status changes to `CONFIRMED`, paymentStatus to `PAID`
6. ✅ Policies generated with correct dates and coverage
7. ✅ Audit log entries created for payment creation and status change

---

## Step 9: Expected Failure Flow

```
1. POST /api/payments → 201 (payment_session_id returned)
2. User payment fails on Cashfree checkout → FAILED
3. Cashfree sends webhook → POST /api/payments/webhook → 200
4. GET /api/payments/status/:orderId → 200 (status: FAILED)
5. Database: Payment.status = FAILED, Order.paymentStatus = FAILED
6. NO policies generated
```

### Verify the failure flow:

1. ✅ Payment record remains / updates to `FAILED` status
2. ✅ Order `paymentStatus` changes to `FAILED`
3. ✅ Order `status` stays `PENDING` (not confirmed)
4. ✅ No policies generated
5. ✅ User can retry payment — call `POST /api/payments` again with the same `orderId`
6. ✅ A new Cashfree order is created (old FAILED payment is replaced)

---

## Postman Collection Summary

| # | Method | URL | Auth | Description |
|---|--------|-----|------|-------------|
| 1 | POST | `/api/auth/send-otp` | None | Send OTP |
| 2 | POST | `/api/auth/verify-otp` | None | Verify OTP, get JWT |
| 3 | POST | `/api/orders` | Bearer | Create order |
| 4 | POST | `/api/payments` | Bearer | Create payment → get `paymentSessionId` |
| 5 | GET | `/api/payments/status/:orderId` | Bearer | Verify payment status |
| 6 | POST | `/api/payments/webhook` | None | Webhook (Cashfree calls this) |
| 7 | GET | `/api/payments/:id` | Bearer | Get payment by ID |
| 8 | GET | `/api/payments/order/:orderId` | Bearer | Get payment by order |
| 9 | GET | `/api/orders/:id` | Bearer | Verify order status |
| 10 | GET | `/api/policies/my` | Bearer | View generated policies |
