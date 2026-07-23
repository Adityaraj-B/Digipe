# DigiPe Backend — API Testing Guide

This guide provides step-by-step Postman testing instructions for all new and modified APIs.

> **Prerequisites**: 
> - Server running at `http://localhost:<PORT>/api`
> - Admin JWT token (login as admin user)
> - Customer JWT token (login as customer)

---

## 1. Admin: Configure Price Settings

### 1.1 Get Current Price Settings
```
GET /api/admin/price-settings
Authorization: Bearer <ADMIN_TOKEN>
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Price settings fetched successfully",
  "data": {
    "_id": "...",
    "promotionalDiscount": { "percentage": 0, "isActive": false },
    "tax": { "gstPercentage": 18 },
    "updatedBy": null
  }
}
```

### 1.2 Update Promotional Discount
```
PUT /api/admin/price-settings/discount
Authorization: Bearer <ADMIN_TOKEN>
Content-Type: application/json

{
  "percentage": 10,
  "isActive": true
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Promotional discount updated successfully",
  "data": {
    "promotionalDiscount": { "percentage": 10, "isActive": true },
    "tax": { "gstPercentage": 18 }
  }
}
```

### 1.3 Update Tax/GST
```
PUT /api/admin/price-settings/tax
Authorization: Bearer <ADMIN_TOKEN>
Content-Type: application/json

{
  "gstPercentage": 18
}
```

---

## 2. Customer: Submit Application

### 2.1 Create Application
```
POST /api/applications
Authorization: Bearer <CUSTOMER_TOKEN>
Content-Type: application/json

{
  "planId": "<PLAN_ID>",
  "fieldValues": [
    {
      "productField": "<FIELD_ID>",
      "fieldName": "fullName",
      "fieldValue": "John Doe"
    }
  ]
}
```

---

## 3. Customer: Upload Documents (4+ Images + Videos)

### 3.1 Upload Single Document
```
POST /api/documents/upload
Authorization: Bearer <CUSTOMER_TOKEN>
Content-Type: multipart/form-data

file: <select file>
applicationId: <APPLICATION_ID> (optional)
```

### 3.2 Upload Multiple Documents (NEW)
```
POST /api/documents/upload-multiple
Authorization: Bearer <CUSTOMER_TOKEN>
Content-Type: multipart/form-data

files: <select multiple files (4+ images, videos)>
applicationId: <APPLICATION_ID> (optional)
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Document uploaded successfully",
  "data": [
    {
      "_id": "...",
      "originalName": "photo1.jpg",
      "url": "https://res.cloudinary.com/...",
      "fileType": "IMAGE",
      "application": "<APPLICATION_ID>"
    },
    {
      "_id": "...",
      "originalName": "video1.mp4",
      "url": "https://res.cloudinary.com/...",
      "fileType": "VIDEO",
      "application": "<APPLICATION_ID>"
    }
  ]
}
```

---

## 4. Admin: Review & Approve Application

### 4.1 Get All Applications
```
GET /api/applications
Authorization: Bearer <ADMIN_TOKEN>
```

### 4.2 Approve Application (Auto-creates Consent)
```
PATCH /api/applications/<APPLICATION_ID>/status
Authorization: Bearer <ADMIN_TOKEN>
Content-Type: application/json

{
  "status": "APPROVED",
  "remarks": "All documents verified, application approved"
}
```

**Side Effect**: A `Consent` record is automatically created with `adminApproval: true`.

---

## 5. Consent Management

### 5.1 Get Consent Status (Customer)
```
GET /api/applications/<APPLICATION_ID>/consent
Authorization: Bearer <CUSTOMER_TOKEN>
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Consent details fetched successfully",
  "data": {
    "application": "<APPLICATION_ID>",
    "user": { "name": "John Doe", "mobileNumber": "+91..." },
    "adminUser": { "name": "Super Admin" },
    "userConsent": false,
    "adminApproval": true,
    "approvalTimestamp": "2026-06-06T..."
  }
}
```

### 5.2 Record User Consent (Customer)
```
POST /api/applications/<APPLICATION_ID>/consent
Authorization: Bearer <CUSTOMER_TOKEN>
```

### 5.3 Admin: View Consent
```
GET /api/admin/consents/<APPLICATION_ID>
Authorization: Bearer <ADMIN_TOKEN>
```

---

## 6. Customer: Create Order

```
POST /api/orders
Authorization: Bearer <CUSTOMER_TOKEN>
Content-Type: application/json

{
  "items": [
    {
      "planId": "<PLAN_ID>",
      "applicationId": "<APPROVED_APPLICATION_ID>"
    }
  ]
}
```

**Expected Response** (with 10% discount, 18% GST on ₹1000 plan):
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "orderNumber": "ORD-...",
    "subtotal": 1000,
    "discountPercentage": 10,
    "discountAmount": 100,
    "gstPercentage": 18,
    "taxAmount": 162,
    "totalAmount": 1062,
    "status": "PENDING",
    "paymentStatus": "PENDING"
  }
}
```

---

## 7. Payment Guard Testing

### 7.1 Attempt Payment with Non-Approved Application
```
POST /api/payments
Authorization: Bearer <CUSTOMER_TOKEN>
Content-Type: application/json

{
  "orderId": "<ORDER_ID_WITH_UNAPPROVED_APP>"
}
```

**Expected Response (403):**
```json
{
  "success": false,
  "message": "Payment is not allowed until all applications are approved by admin"
}
```

### 7.2 Attempt Payment with Approved Application
```
POST /api/payments
Authorization: Bearer <CUSTOMER_TOKEN>
Content-Type: application/json

{
  "orderId": "<ORDER_ID_WITH_APPROVED_APP>"
}
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "Payment session created successfully",
  "data": {
    "payment_session_id": "session_...",
    "cashfreeOrderId": "cf_..."
  }
}
```

---

## 8. Admin: Order Management

### 8.1 List All Orders
```
GET /api/admin/orders?page=1&limit=10&status=PENDING
Authorization: Bearer <ADMIN_TOKEN>
```

### 8.2 Get Detailed Order View (NEW)
```
GET /api/admin/orders/<ORDER_ID>
Authorization: Bearer <ADMIN_TOKEN>
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "order": {
      "orderNumber": "ORD-...",
      "subtotal": 1000,
      "discountAmount": 100,
      "taxAmount": 162,
      "totalAmount": 1062,
      "status": "PENDING",
      "displayStatus": "Pending Payment"
    },
    "customer": {
      "name": "John Doe",
      "mobileNumber": "+91...",
      "email": "john@example.com"
    },
    "planDetails": [{
      "planName": "Basic Plan",
      "productName": "Health Insurance",
      "coverageAmount": 500000,
      "premium": 1000
    }],
    "verificationDetails": {
      "fieldValues": [
        { "fieldName": "Full Name", "fieldValue": "John Doe" }
      ],
      "documents": [
        { "fileUrl": "https://...", "fileType": "IMAGE" }
      ]
    },
    "uploadedImages": [...],
    "uploadedVideos": [...],
    "consent": {
      "userConsent": true,
      "adminApproval": true
    },
    "currentStatus": "Pending Payment"
  }
}
```

---

## 9. Customer: Submit Claim (Updated)

### 9.1 Create Claim with Images, Videos, Reason
```
POST /api/claims
Authorization: Bearer <CUSTOMER_TOKEN>
Content-Type: application/json

{
  "policyId": "<ACTIVE_POLICY_ID>",
  "description": "Detailed description of the claim",
  "reason": "Accident damage",
  "incidentDate": "2026-06-01T10:30:00.000Z",
  "claimAmount": 25000,
  "images": ["<DOC_ID_1>", "<DOC_ID_2>", "<DOC_ID_3>", "<DOC_ID_4>"],
  "videos": ["<DOC_ID_5>"]
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Claim submitted successfully",
  "data": {
    "claimNumber": "CLM-...",
    "description": "Detailed description of the claim",
    "reason": "Accident damage",
    "incidentDate": "2026-06-01T10:30:00.000Z",
    "claimAmount": 25000,
    "status": "SUBMITTED",
    "documents": [
      { "document": { "originalName": "photo1.jpg", "url": "..." }, "documentType": "PHOTO" },
      { "document": { "originalName": "video1.mp4", "url": "..." }, "documentType": "OTHER" }
    ]
  }
}
```

---

## 10. Admin: Claim Management

### 10.1 List All Claims
```
GET /api/claims?status=SUBMITTED
Authorization: Bearer <ADMIN_TOKEN>
```

### 10.2 Get Claim Detail
```
GET /api/claims/<CLAIM_ID>
Authorization: Bearer <ADMIN_TOKEN>
```

### 10.3 Update Claim Status
```
PATCH /api/claims/<CLAIM_ID>/status
Authorization: Bearer <ADMIN_TOKEN>
Content-Type: application/json

{
  "status": "SETTLED",
  "remarks": "Claim verified and settled",
  "settledAmount": 20000
}
```

**Status transitions:**
- `SUBMITTED` → `UNDER_REVIEW`
- `UNDER_REVIEW` → `APPROVED` / `REJECTED`
- `APPROVED` → `SETTLED`

---

## 11. End-to-End Flow Summary

```
Step 1: Admin sets price settings (discount + GST)
Step 2: Customer selects product → plan → submits application
Step 3: Customer uploads 4+ images and videos
Step 4: Admin reviews and approves application → Consent auto-created
Step 5: Customer records consent
Step 6: Customer creates order (amounts include discount + GST)
Step 7: Customer initiates payment (blocked if not approved)
Step 8: Payment success → Policy auto-generated
Step 9: Admin views detailed order info
Step 10: Customer submits claim (with reason, incident date, media)
Step 11: Admin manages claim (In Review → Settled/Rejected)
```
