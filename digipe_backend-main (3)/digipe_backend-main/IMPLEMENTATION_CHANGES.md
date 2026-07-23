# DigiPe Backend — Implementation Changes

## Overview

This document describes the backend changes made to the DigiPe Insurance Marketplace to support the latest business requirements. All changes follow the existing architecture pattern (Controller → Service → Repository → Model) and coding style.

---

## 1. Admin Price Settings

### New Files
- `models/adminPriceSettings.model.js` — Singleton MongoDB schema for global discount and tax configuration
- `repositories/adminPriceSettings.repository.js` — Data access with `getSettings()` and `upsertSettings()`
- `services/adminPriceSettings.service.js` — Business logic including `calculateFinalAmount(subtotal)` that applies active discount + GST
- `controllers/adminPriceSettings.controller.js` — API handlers for CRUD
- `validators/adminPriceSettings.validator.js` — Joi schemas for request validation

### API Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/price-settings` | Get current price settings |
| PUT | `/api/admin/price-settings/discount` | Update promotional discount (percentage + isActive) |
| PUT | `/api/admin/price-settings/tax` | Update GST percentage |

### Price Calculation Logic
When an order is created, the system:
1. Sums all plan premiums → `subtotal`
2. If promotional discount is active, applies `discountAmount = subtotal × discountPercentage / 100`
3. Applies GST on the discounted amount → `taxAmount = (subtotal - discountAmount) × gstPercentage / 100`
4. Stores `subtotal`, `discountPercentage`, `discountAmount`, `gstPercentage`, `taxAmount`, and `totalAmount` on the Order

---

## 2. User Purchase Flow — Admin Approval Gate

### Modified Files
- `services/payment.service.js` — Added approval verification in `createPayment()`
- `services/order.service.js` — Integrated `adminPriceSettingsService.calculateFinalAmount()` for price breakdown

### Key Changes
**CRITICAL**: Before creating a Cashfree payment session, the system now:
1. Fetches all order items
2. For each item, loads the linked `InsuranceApplication`
3. Verifies `application.status === APPROVED`
4. If ANY application is not approved, throws `403 Forbidden` with message: *"Payment is not allowed until all applications are approved by admin"*

### Order Schema Changes
Added fields: `application`, `subtotal`, `discountPercentage`, `discountAmount`, `gstPercentage`, `taxAmount`

---

## 3. Admin Order Management

### Modified Files
- `services/adminOrder.service.js` — Added `getOrderDetail()` method
- `controllers/adminOrder.controller.js` — Added `getOrderDetail` handler
- `routes/admin.routes.js` — Added `GET /api/admin/orders/:id`

### API Response Structure
The `GET /api/admin/orders/:id` endpoint returns:
- **order** — Order amounts, status, dates
- **customer** — Name, mobile, email, profile image
- **planDetails** — Plan name, product, coverage, premium, features
- **verificationDetails** — Field values (form data) and uploaded verification documents
- **uploadedImages** — All user images (fileUrl, fileType, uploadedAt)
- **uploadedVideos** — All user videos (fileUrl, fileType, uploadedAt)
- **policies** — Active/generated policies
- **consent** — Consent record status
- **currentStatus** — Computed display status

---

## 4. Document Upload Enhancement

### Modified Files
- `models/document.model.js` — Added `fileType` (IMAGE/VIDEO/DOCUMENT) and `application` reference
- `services/document.service.js` — Added `uploadMultiple()` and auto `fileType` detection from MIME type
- `controllers/document.controller.js` — Added `uploadMultiple` handler
- `routes/document.routes.js` — Added video MIME types, increased size to 50MB, added `/upload-multiple` route
- `repositories/document.repository.js` — Added `findByApplication()` method

### Supported MIME Types
- **Images**: JPEG, PNG, GIF, WebP
- **Videos**: MP4, MPEG, QuickTime, AVI, WebM, 3GP
- **Documents**: PDF, DOC, DOCX

### API Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/documents/upload` | Upload single file (enhanced with `applicationId` support) |
| POST | `/api/documents/upload-multiple` | Upload up to 20 files at once |

---

## 5. Consent Management

### New Files
- `models/consent.model.js` — Schema with `application`, `user`, `adminUser`, consent flags, timestamps
- `repositories/consent.repository.js` — Data access
- `services/consent.service.js` — `createConsent()`, `getByApplication()`, `recordUserConsent()`
- `controllers/consent.controller.js` — API handlers
- `validators/consent.validator.js` — Joi schemas

### Auto-Creation
When admin approves an application (`PATCH /api/applications/:id/status` with `status: "APPROVED"`), a consent record is automatically created with `adminApproval: true`.

### API Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/applications/:id/consent` | Get consent status for an application |
| POST | `/api/applications/:id/consent` | Record user consent |
| GET | `/api/admin/consents/:id` | Admin: Get consent details by application ID |

---

## 6. Claim Module Update

### Modified Files
- `models/claim.model.js` — Added `reason` and `incidentDate` fields
- `services/claim.service.js` — Accepts `reason`, `incidentDate`, `images[]`, `videos[]` during creation; auto-links as ClaimDocuments
- `validators/claim.validator.js` — Added validation for new fields

### Claim Creation Flow (Updated)
1. User submits claim with `policyId`, `description`, `reason`, `incidentDate`, `claimAmount`, `images[]`, `videos[]`
2. System validates policy is active, no existing active claim
3. Creates claim record with new fields
4. For each image/video document ID, creates a `ClaimDocument` record automatically
5. Returns fully populated claim with documents

---

## 7. Constants & Messages

### Added Constants
- `FILE_TYPES` enum: `{ IMAGE, VIDEO, DOCUMENT }`

### Added Messages
- `PRICE_SETTINGS`: FETCHED, DISCOUNT_UPDATED, TAX_UPDATED, NOT_FOUND
- `CONSENT`: CREATED, FETCHED, USER_CONSENT_RECORDED, NOT_FOUND, ALREADY_EXISTS
- `PAYMENT.NOT_APPROVED`: "Payment is not allowed until all applications are approved by admin"

---

## Schema Changes Summary

| Model | New Fields | Impact |
|-------|-----------|--------|
| Order | `application`, `subtotal`, `discountPercentage`, `discountAmount`, `gstPercentage`, `taxAmount` | Backward-compatible (all have defaults) |
| Document | `fileType`, `application` | Backward-compatible (defaults provided) |
| Claim | `reason`, `incidentDate` | Backward-compatible (`default: null`) |
| AdminPriceSettings | **New model** | No impact on existing data |
| Consent | **New model** | No impact on existing data |

---

## Backward Compatibility

All changes are **fully backward-compatible**:
- New schema fields have defaults — existing documents continue to work
- No existing APIs were removed or had their signatures changed
- The payment approval gate is the only behavioral change — existing flows that already ensure approval will work identically
