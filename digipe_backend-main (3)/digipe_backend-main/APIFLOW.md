# DigiPe Insurance API — Complete Testing Flow

Swagger UI: **http://localhost:5000/api-docs**  
Health Check: **http://localhost:5000/health**

> **How to use this doc:**  
> Follow each phase top-to-bottom. Every response gives you IDs — copy them into the next request body exactly where indicated. Fields marked `REPLACE_WITH_...` must be filled with real IDs from previous responses.

---

## Setup: Start the Server

```bash
npm install
npm run dev      # or: node src/server.js
```

The admin user is auto-seeded on startup:
- **Mobile:** `+918604707494`
- **Role:** ADMIN

---

---

## PHASE 1 — Admin Login

> Admin must login first to set up the catalog before customers can use the app.

---

### Step 1.1 — Send OTP to Admin

**POST** `/api/auth/send-otp`  
Auth: None

**Request Body:**
```json
{
  "mobileNumber": "+918604707494"
}
```

**What to save from response:** Nothing yet. OTP is sent via WhatsApp (Surefy Auth).

---

### Step 1.2 — Verify OTP (Admin Login)

**POST** `/api/auth/verify-otp`  
Auth: None

**Request Body:**
```json
{
  "mobileNumber": "+918604707494",
  "code": "123456"
}
```

> Replace `123456` with the real OTP received on the admin's phone.

**What to save from response:**
```
token → ADMIN_TOKEN   (copy the "token" field from response.data)
```

> In Swagger: click **Authorize** (top right) → paste `ADMIN_TOKEN` → click **Authorize**.

---

---

## PHASE 2 — Admin: Build the Catalog

> All steps in this phase require the **Admin token** set in Swagger Authorize.

---

### Step 2.1 — Create a Category

**POST** `/api/categories`  
Auth: Admin token

**Request Body:**
```json
{
  "name": "Health Insurance",
  "description": "Medical and health coverage plans for individuals and families",
  "icon": "health-icon",
  "isActive": true,
  "sortOrder": 1
}
```

**What to save from response:**
```
data._id → CATEGORY_ID
```

---

### Step 2.2 — Create a Product

**POST** `/api/products`  
Auth: Admin token

**Request Body:**
```json
{
  "category": "REPLACE_WITH_CATEGORY_ID",
  "name": "Individual Health Plan",
  "description": "Comprehensive health insurance plan covering hospitalization, surgery, and critical illness for individuals.",
  "shortDescription": "Full health coverage for individuals",
  "features": [
    "Cashless hospitalization",
    "No claim bonus",
    "Pre and post hospitalization coverage",
    "Day care procedures covered"
  ],
  "isActive": true,
  "sortOrder": 1
}
```

**What to save from response:**
```
data._id → PRODUCT_ID
```

---

### Step 2.3 — Create a Plan

**POST** `/api/plans`  
Auth: Admin token

**Request Body:**
```json
{
  "product": "REPLACE_WITH_PRODUCT_ID",
  "name": "Gold Plan - ₹5 Lakh Cover",
  "description": "Best suited for individuals aged 18-45. Covers hospitalization and critical illness.",
  "coverageAmount": 500000,
  "premium": 8500,
  "premiumFrequency": "YEARLY",
  "duration": 12,
  "features": [
    "Sum insured: ₹5,00,000",
    "Room rent: Single AC room",
    "Pre-existing diseases covered after 2 years"
  ],
  "benefits": [
    "Free annual health check-up",
    "Tax benefit under Section 80D"
  ],
  "exclusions": [
    "Cosmetic surgery",
    "Self-inflicted injuries",
    "War and nuclear perils"
  ],
  "isActive": true,
  "sortOrder": 1
}
```

**What to save from response:**
```
data._id → PLAN_ID
```

---

### Step 2.4 — Create Product Fields (Application Form Fields)

> These fields define what the customer must fill in when applying for this product.  
> Create each field one at a time. At minimum create these 3 fields.

#### Field 1 — Full Name (TEXT)

**POST** `/api/product-fields`  
Auth: Admin token

**Request Body:**
```json
{
  "product": "REPLACE_WITH_PRODUCT_ID",
  "fieldName": "fullName",
  "fieldLabel": "Full Name",
  "fieldType": "TEXT",
  "placeholder": "Enter your full name as per Aadhaar",
  "isRequired": true,
  "sortOrder": 1
}
```

**What to save from response:**
```
data._id → FIELD_ID_1   (fullName field)
```

---

#### Field 2 — Date of Birth (DATE)

**POST** `/api/product-fields`  
Auth: Admin token

**Request Body:**
```json
{
  "product": "REPLACE_WITH_PRODUCT_ID",
  "fieldName": "dateOfBirth",
  "fieldLabel": "Date of Birth",
  "fieldType": "DATE",
  "placeholder": "YYYY-MM-DD",
  "isRequired": true,
  "sortOrder": 2
}
```

**What to save from response:**
```
data._id → FIELD_ID_2   (dateOfBirth field)
```

---

#### Field 3 — Pre-existing Disease (SELECT)

**POST** `/api/product-fields`  
Auth: Admin token

**Request Body:**
```json
{
  "product": "REPLACE_WITH_PRODUCT_ID",
  "fieldName": "preExistingDisease",
  "fieldLabel": "Do you have any pre-existing disease?",
  "fieldType": "SELECT",
  "placeholder": "Select an option",
  "isRequired": true,
  "options": [
    { "label": "None", "value": "none", "sortOrder": 1 },
    { "label": "Diabetes", "value": "diabetes", "sortOrder": 2 },
    { "label": "Hypertension", "value": "hypertension", "sortOrder": 3 },
    { "label": "Heart Disease", "value": "heart_disease", "sortOrder": 4 }
  ],
  "sortOrder": 3
}
```

**What to save from response:**
```
data._id → FIELD_ID_3   (preExistingDisease field)
```

---

---

## PHASE 3 — Customer Login

> A new customer registers automatically when they verify OTP for the first time.

---

### Step 3.1 — Send OTP to Customer

**POST** `/api/auth/send-otp`  
Auth: None

**Request Body:**
```json
{
  "mobileNumber": "+919876543210"
}
```

> Use any valid mobile number registered with the Surefy/Digipe system.

---

### Step 3.2 — Verify OTP (Customer Login)

**POST** `/api/auth/verify-otp`  
Auth: None

**Request Body:**
```json
{
  "mobileNumber": "+919876543210",
  "code": "123456"
}
```

**What to save from response:**
```
token → CUSTOMER_TOKEN
```

> In Swagger: replace the Authorize token with `CUSTOMER_TOKEN` to act as customer for the next phases.

---

### Step 3.3 — Update Customer Profile (Optional)

**PUT** `/api/auth/profile`  
Auth: Customer token

**Request Body:**
```json
{
  "name": "Ravi Kumar",
  "email": "ravi.kumar@example.com"
}
```

---

---

## PHASE 4 — Customer: Browse Catalog (No Auth Needed)

> These are public read-only endpoints. No token required.

---

### Step 4.1 — Get All Categories

**GET** `/api/categories`  
Auth: None

Query params (optional): `?page=1&limit=10`

> Confirm your category from Phase 2 appears here.

---

### Step 4.2 — Get All Products

**GET** `/api/products`  
Auth: None

Query params (optional): `?page=1&limit=10`

---

### Step 4.3 — Get Plans for a Product

**GET** `/api/plans/product/{productId}`  
Auth: None

Replace `{productId}` with `PRODUCT_ID` from Step 2.2.

> Confirm your Gold Plan appears here with `PLAN_ID`.

---

### Step 4.4 — Get Application Form Fields for a Product

**GET** `/api/product-fields/product/{productId}`  
Auth: None

Replace `{productId}` with `PRODUCT_ID`.

> This shows the form fields the customer must fill in when submitting an application.  
> Note the `_id` of each field — you need them in Step 5.1.

---

---

## PHASE 5 — Customer: Submit Insurance Application

---

### Step 5.1 — Submit Application

**POST** `/api/applications`  
Auth: Customer token

**Request Body:**
```json
{
  "planId": "REPLACE_WITH_PLAN_ID",
  "fieldValues": [
    {
      "productField": "REPLACE_WITH_FIELD_ID_1",
      "fieldName": "fullName",
      "fieldValue": "Ravi Kumar"
    },
    {
      "productField": "REPLACE_WITH_FIELD_ID_2",
      "fieldName": "dateOfBirth",
      "fieldValue": "1992-05-15"
    },
    {
      "productField": "REPLACE_WITH_FIELD_ID_3",
      "fieldName": "preExistingDisease",
      "fieldValue": "none"
    }
  ]
}
```

**What to save from response:**
```
data._id → APPLICATION_ID
data.status → should be "SUBMITTED"
```

---

### Step 5.2 — View My Applications (Customer)

**GET** `/api/applications/my`  
Auth: Customer token

> Confirm the application appears with status `SUBMITTED`.

---

---

## PHASE 6 — Admin: Review & Approve Application

> Switch back to the Admin token in Swagger Authorize.

---

### Step 6.1 — View All Applications (Admin)

**GET** `/api/applications`  
Auth: Admin token

> Find the customer's application. Copy its `_id` if you don't have `APPLICATION_ID` already.

---

### Step 6.2 — Approve the Application

**PATCH** `/api/applications/{id}/status`  
Auth: Admin token

Replace `{id}` with `APPLICATION_ID`.

**Request Body:**
```json
{
  "status": "APPROVED",
  "remarks": "All details verified. Application approved."
}
```

**What to confirm from response:**
```
data.status → "APPROVED"
```

> Other valid status values: `UNDER_REVIEW`, `REJECTED`

---

---

## PHASE 7 — Customer: Create Order

> Switch back to the Customer token in Swagger Authorize.

---

### Step 7.1 — Create Order Directly

**POST** `/api/orders`  
Auth: Customer token

**Request Body:**
```json
{
  "items": [
    {
      "planId": "REPLACE_WITH_PLAN_ID",
      "applicationId": "REPLACE_WITH_APPLICATION_ID"
    }
  ]
}
```

> To purchase multiple plans at once, add more objects to the `items` array.  
> Each item must have its own approved application.

**What to save from response:**
```
data._id       → ORDER_ID
data.orderNumber → e.g., ORD-A1B2C3D4
data.totalAmount → e.g., 8500
data.status    → "PENDING"
data.paymentStatus → "PENDING"
```

---

### Step 7.2 — View My Orders (Customer)

**GET** `/api/orders/my`  
Auth: Customer token

> Confirm the order appears with status `PENDING`.

---

---

## PHASE 8 — Customer: Make Payment

---

### Step 8.1 — Record Payment

**POST** `/api/payments`  
Auth: Customer token

**Request Body:**
```json
{
  "orderId": "REPLACE_WITH_ORDER_ID",
  "paymentMethod": "UPI"
}
```

> Valid `paymentMethod` values: `CREDIT_CARD`, `DEBIT_CARD`, `NET_BANKING`, `UPI`, `WALLET`

**What to save from response:**
```
data._id           → PAYMENT_ID
data.transactionId → e.g., TXN-XXXXXXXXXXXX
data.status        → "SUCCESS"
```

**What happens automatically after payment:**
- Order status changes to `CONFIRMED`
- Order paymentStatus changes to `PAID`
- One **Policy** is auto-generated for each order item

---

### Step 8.2 — View Payment Details

**GET** `/api/payments/{id}`  
Auth: Customer token

Replace `{id}` with `PAYMENT_ID`.

---

---

## PHASE 9 — Customer: View Policy

---

### Step 9.1 — View My Policies

**GET** `/api/policies/my`  
Auth: Customer token

**What to save from response:**
```
data[0]._id    → POLICY_ID
data[0].status → "ACTIVE"
data[0].policyNumber → e.g., POL-XXXXXXXX
data[0].startDate
data[0].endDate
data[0].coverageAmount → 500000
```

---

### Step 9.2 — View Single Policy Details

**GET** `/api/policies/{id}`  
Auth: Customer token

Replace `{id}` with `POLICY_ID`.

> This shows full plan details, linked application, and any claims.

---

---

## PHASE 10 — Customer: File a Claim

---

### Step 10.1 — Submit Claim

**POST** `/api/claims`  
Auth: Customer token

**Request Body:**
```json
{
  "policyId": "REPLACE_WITH_POLICY_ID",
  "description": "Hospitalized for 5 days due to dengue fever. Requesting reimbursement for hospital bills and medicines.",
  "claimAmount": 45000
}
```

**What to save from response:**
```
data._id          → CLAIM_ID
data.claimNumber  → e.g., CLM-XXXXXXXX
data.status       → "SUBMITTED"
```

---

### Step 10.2 — View My Claims

**GET** `/api/claims/my`  
Auth: Customer token

---

---

## PHASE 11 — Admin: Review & Settle Claim

> Switch back to the Admin token in Swagger Authorize.

---

### Step 11.1 — View All Claims (Admin)

**GET** `/api/claims`  
Auth: Admin token

> Find the claim submitted by the customer.

---

### Step 11.2 — Move Claim to Under Review

**PATCH** `/api/claims/{id}/status`  
Auth: Admin token

Replace `{id}` with `CLAIM_ID`.

**Request Body:**
```json
{
  "status": "UNDER_REVIEW",
  "remarks": "Documents received. Under verification."
}
```

---

### Step 11.3 — Approve and Settle Claim

**PATCH** `/api/claims/{id}/status`  
Auth: Admin token

**Request Body:**
```json
{
  "status": "SETTLED",
  "remarks": "Claim verified and approved. Settlement amount disbursed.",
  "settledAmount": 43500
}
```

**What to confirm from response:**
```
data.status        → "SETTLED"
data.settledAmount → 43500
data.settledAt     → timestamp
```

> Valid claim status flow: `SUBMITTED` → `UNDER_REVIEW` → `APPROVED` → `SETTLED`  
> Or: `SUBMITTED` → `UNDER_REVIEW` → `REJECTED`

---

---

## PHASE 12 — Admin: Dashboard & Order Management

---

### Step 12.1 — Admin Dashboard

**GET** `/api/admin/dashboard`  
Auth: Admin token

> Shows total counts: users, products, applications, orders, policies, claims, revenue.

Optional query: `?productId=REPLACE_WITH_PRODUCT_ID` to filter metrics by product.

---

### Step 12.2 — Admin: View All Orders

**GET** `/api/admin/orders`  
Auth: Admin token

Query params: `?page=1&limit=10&status=CONFIRMED`

---

### Step 12.3 — Admin: Update Order Status

**PATCH** `/api/admin/orders/{id}/status`  
Auth: Admin token

Replace `{id}` with `ORDER_ID`.

**Request Body:**
```json
{
  "status": "CANCELLED"
}
```

---

---

## Quick Reference: ID Chain

```
CATEGORY_ID   ← from Step 2.1
     ↓
PRODUCT_ID    ← from Step 2.2  (needs CATEGORY_ID)
     ↓
PLAN_ID       ← from Step 2.3  (needs PRODUCT_ID)
FIELD_ID_1    ← from Step 2.4  (needs PRODUCT_ID)
FIELD_ID_2    ← from Step 2.4  (needs PRODUCT_ID)
FIELD_ID_3    ← from Step 2.4  (needs PRODUCT_ID)
     ↓
APPLICATION_ID ← from Step 5.1 (needs PLAN_ID + FIELD_IDs)
     ↓
     [Admin approves → Step 6.2]
     ↓
ORDER_ID      ← from Step 7.1  (needs PLAN_ID + APPLICATION_ID)
     ↓
PAYMENT_ID    ← from Step 8.1  (needs ORDER_ID)
     ↓          [Policy auto-created]
POLICY_ID     ← from Step 9.1
     ↓
CLAIM_ID      ← from Step 10.1 (needs POLICY_ID)
```

---

## Token Reference

| Token | Who | When to Use |
|---|---|---|
| `ADMIN_TOKEN` | Admin (`+918604707494`) | Phase 2, 6, 11, 12 |
| `CUSTOMER_TOKEN` | Customer (`+919876543210`) | Phase 3, 4, 5, 7, 8, 9, 10 |

---

## Common Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| `401 Unauthorized` | Token missing or expired | Re-login and set token in Swagger Authorize |
| `403 Forbidden` | Wrong role (customer hitting admin route) | Use the Admin token |
| `400 Application must be approved` | Tried to create order before admin approved | Complete Step 6.2 first |
| `400 Application does not belong to user` | Using another user's applicationId | Use APPLICATION_ID from the same logged-in customer |
| `404 Plan not found` | Wrong planId | Double-check PLAN_ID from Step 2.3 |
| `409 Conflict` | Submitting duplicate application for same plan | Each plan can only have one application per customer |