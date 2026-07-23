const applicationRepository = require('../repositories/application.repository');
const applicationFieldValueRepository = require('../repositories/applicationFieldValue.repository');
const planRepository = require('../repositories/plan.repository');
const productRepository = require('../repositories/product.repository');
const auditLogService = require('./auditLog.service');
const consentService = require('./consent.service');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const { generateApplicationNumber } = require('../utils/helpers');
const { buildPaginationMeta } = require('../utils/pagination');
const { AUDIT_ACTIONS, APPLICATION_STATUS } = require('../constants');

class ApplicationService {
  /**
   * Submit a new insurance application with dynamic field values.
   */
  async create(userId, data) {
    const plan = await planRepository.findById(data.planId);
    if (!plan) {
      throw ApiError.notFound(messages.PLAN.NOT_FOUND);
    }

    const product = await productRepository.findById(plan.product);
    if (!product) {
      throw ApiError.notFound(messages.PRODUCT.NOT_FOUND);
    }

    // Check for duplicate application
    const existing = await applicationRepository.findByUserAndPlan(userId, data.planId);
    if (existing) {
      throw ApiError.conflict(messages.APPLICATION.ALREADY_SUBMITTED);
    }

    // Create application
    const application = await applicationRepository.create({
      user: userId,
      product: plan.product,
      plan: data.planId,
      applicationNumber: generateApplicationNumber(),
      status: APPLICATION_STATUS.SUBMITTED,
    });

    // Save dynamic field values
    if (data.fieldValues && Array.isArray(data.fieldValues) && data.fieldValues.length > 0) {
      const fieldValueDocs = data.fieldValues.map((fv) => ({
        application: application._id,
        productField: fv.productField,
        fieldName: fv.fieldName,
        fieldValue: fv.fieldValue,
      }));
      await applicationFieldValueRepository.createMany(fieldValueDocs);
    }

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.CREATE,
      entityType: 'InsuranceApplication',
      entityId: application._id,
      newData: { applicationNumber: application.applicationNumber, planId: data.planId },
    });

    const populatedApp = await applicationRepository.findByIdWithDetails(application._id);
    return populatedApp;
  }

  /**
   * Get all applications for a customer.
   */
  async getMyApplications(userId, options) {
    const { docs, totalDocs } = await applicationRepository.findByUser(userId, options);
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { applications: docs, meta };
  }

  /**
   * Get all applications (admin).
   */
  async getAll(filter, options) {
    const { docs, totalDocs } = await applicationRepository.findWithPagination(filter, {
      ...options,
      populate: [
        { path: 'user', select: 'name mobileNumber email' },
        { path: 'product', select: 'name slug' },
        { path: 'plan', select: 'name coverageAmount premium' },
      ],
    });
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { applications: docs, meta };
  }

  /**
   * Get single application by ID with all details.
   */
  async getById(id) {
    const application = await applicationRepository.findByIdWithDetails(id);
    if (!application) {
      throw ApiError.notFound(messages.APPLICATION.NOT_FOUND);
    }
    return application;
  }

  /**
   * Update application status (admin action).
   */
  async updateStatus(id, statusData, adminUserId) {
    const application = await applicationRepository.findById(id);
    if (!application) {
      throw ApiError.notFound(messages.APPLICATION.NOT_FOUND);
    }

    const previousStatus = application.status;
    const updateData = {
      status: statusData.status,
      remarks: statusData.remarks || null,
      reviewedBy: adminUserId,
      reviewedAt: new Date(),
    };

    const updated = await applicationRepository.updateById(id, updateData);

    // Auto-create consent record when application is approved
    if (statusData.status === APPLICATION_STATUS.APPROVED) {
      await consentService.createConsent(id, adminUserId);
    }

    await auditLogService.log({
      user: adminUserId,
      action: AUDIT_ACTIONS.STATUS_CHANGE,
      entityType: 'InsuranceApplication',
      entityId: id,
      previousData: { status: previousStatus },
      newData: { status: statusData.status, remarks: statusData.remarks },
    });

    return updated;
  }
}

module.exports = new ApplicationService();
