/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       properties:
 *         _id: { type: string }
 *         name: { type: string }
 *         mobileNumber: { type: string }
 *         email: { type: string }
 *         role: { type: string, enum: [ADMIN, CUSTOMER] }
 *         profileImage: { type: string }
 *         isActive: { type: boolean }
 *         createdAt: { type: string, format: date-time }
 *         updatedAt: { type: string, format: date-time }
 *
 *     InsuranceCategory:
 *       type: object
 *       properties:
 *         _id: { type: string }
 *         name: { type: string }
 *         slug: { type: string }
 *         description: { type: string }
 *         icon: { type: string }
 *         image: { type: string }
 *         isActive: { type: boolean }
 *         sortOrder: { type: integer }
 *         createdAt: { type: string, format: date-time }
 *
 *     InsuranceProduct:
 *       type: object
 *       properties:
 *         _id: { type: string }
 *         category: { $ref: '#/components/schemas/InsuranceCategory' }
 *         name: { type: string }
 *         slug: { type: string }
 *         description: { type: string }
 *         shortDescription: { type: string }
 *         image: { type: string }
 *         features: { type: array, items: { type: string } }
 *         isActive: { type: boolean }
 *         sortOrder: { type: integer }
 *
 *     InsurancePlan:
 *       type: object
 *       properties:
 *         _id: { type: string }
 *         product: { type: string }
 *         name: { type: string }
 *         description: { type: string }
 *         coverageAmount: { type: number }
 *         premium: { type: number }
 *         premiumFrequency: { type: string, enum: [MONTHLY, QUARTERLY, HALF_YEARLY, YEARLY] }
 *         duration: { type: integer }
 *         features: { type: array, items: { type: string } }
 *         benefits: { type: array, items: { type: string } }
 *         exclusions: { type: array, items: { type: string } }
 *
 *     ProductField:
 *       type: object
 *       properties:
 *         _id: { type: string }
 *         product: { type: string }
 *         fieldName: { type: string }
 *         fieldLabel: { type: string }
 *         fieldType: { type: string, enum: [TEXT, NUMBER, EMAIL, DATE, SELECT, RADIO, CHECKBOX, TEXTAREA, FILE] }
 *         placeholder: { type: string }
 *         isRequired: { type: boolean }
 *         validationRules:
 *           type: object
 *           properties:
 *             min: { type: number }
 *             max: { type: number }
 *             minLength: { type: integer }
 *             maxLength: { type: integer }
 *             pattern: { type: string }
 *         options:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               label: { type: string }
 *               value: { type: string }
 *               sortOrder: { type: integer }
 *         sortOrder: { type: integer }
 *
 *     InsuranceApplication:
 *       type: object
 *       properties:
 *         _id: { type: string }
 *         user: { type: string }
 *         product: { type: string }
 *         plan: { type: string }
 *         applicationNumber: { type: string }
 *         status: { type: string, enum: [DRAFT, SUBMITTED, UNDER_REVIEW, APPROVED, REJECTED] }
 *         remarks: { type: string }
 *         reviewedBy: { type: string }
 *         reviewedAt: { type: string, format: date-time }
 *         fieldValues:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               productField: { type: string }
 *               fieldName: { type: string }
 *               fieldValue: {}
 *
 *     Order:
 *       type: object
 *       properties:
 *         _id: { type: string }
 *         user: { type: string }
 *         orderNumber: { type: string }
 *         totalAmount: { type: number }
 *         status: { type: string, enum: [PENDING, CONFIRMED, CANCELLED] }
 *         paymentStatus: { type: string, enum: [PENDING, PAID, FAILED, REFUNDED] }
 *         items:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               plan: { type: object }
 *               application: { type: object }
 *               premium: { type: number }
 *               coverageAmount: { type: number }
 *         createdAt: { type: string, format: date-time }
 *
 *     Payment:
 *       type: object
 *       properties:
 *         _id: { type: string }
 *         order: { type: string }
 *         user: { type: string }
 *         amount: { type: number }
 *         paymentMethod: { type: string, enum: [CREDIT_CARD, DEBIT_CARD, NET_BANKING, UPI, WALLET] }
 *         transactionId: { type: string }
 *         status: { type: string, enum: [PENDING, SUCCESS, FAILED, REFUNDED] }
 *         paidAt: { type: string, format: date-time }
 *
 *     Policy:
 *       type: object
 *       properties:
 *         _id: { type: string }
 *         user: { type: string }
 *         order: { type: string }
 *         plan: { type: object }
 *         policyNumber: { type: string }
 *         startDate: { type: string, format: date-time }
 *         endDate: { type: string, format: date-time }
 *         coverageAmount: { type: number }
 *         premium: { type: number }
 *         status: { type: string, enum: [ACTIVE, EXPIRED, CANCELLED, CLAIMED] }
 *
 *     Claim:
 *       type: object
 *       properties:
 *         _id: { type: string }
 *         user: { type: string }
 *         policy: { type: string }
 *         claimNumber: { type: string }
 *         description: { type: string }
 *         claimAmount: { type: number }
 *         status: { type: string, enum: [SUBMITTED, UNDER_REVIEW, APPROVED, REJECTED, SETTLED] }
 *         remarks: { type: string }
 *         settledAmount: { type: number }
 *         documents:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               document: { type: object }
 *               documentType: { type: string }
 *
 *     Document:
 *       type: object
 *       properties:
 *         _id: { type: string }
 *         user: { type: string }
 *         originalName: { type: string }
 *         fileName: { type: string }
 *         mimeType: { type: string }
 *         size: { type: number }
 *         url: { type: string }
 *
 *     ApiResponse:
 *       type: object
 *       properties:
 *         success: { type: boolean }
 *         statusCode: { type: integer }
 *         message: { type: string }
 *         data: { type: object }
 *         meta:
 *           type: object
 *           properties:
 *             totalDocs: { type: integer }
 *             totalPages: { type: integer }
 *             currentPage: { type: integer }
 *             limit: { type: integer }
 *             hasNextPage: { type: boolean }
 *             hasPrevPage: { type: boolean }
 *
 *     ErrorResponse:
 *       type: object
 *       properties:
 *         success: { type: boolean, example: false }
 *         statusCode: { type: integer }
 *         message: { type: string }
 *         errors:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               field: { type: string }
 *               message: { type: string }
 */