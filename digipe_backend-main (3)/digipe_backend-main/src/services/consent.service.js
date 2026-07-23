const consentRepository = require('../repositories/consent.repository');
const applicationRepository = require('../repositories/application.repository');
const auditLogService = require('./auditLog.service');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const { AUDIT_ACTIONS } = require('../constants');

class ConsentService {
  /**
   * Create a consent record when admin approves an application.
   * Called automatically from application.service.updateStatus().
   */
  async createConsent(applicationId, adminUserId) {
    const application = await applicationRepository.findById(applicationId);
    if (!application) {
      throw ApiError.notFound(messages.APPLICATION.NOT_FOUND);
    }

    // Check for existing consent
    const existing = await consentRepository.findByApplication(applicationId);
    if (existing) {
      return existing;
    }

    const consent = await consentRepository.create({
      application: applicationId,
      user: application.user,
      adminUser: adminUserId,
      adminApproval: true,
      approvalTimestamp: new Date(),
    });

    await auditLogService.log({
      user: adminUserId,
      action: AUDIT_ACTIONS.CREATE,
      entityType: 'Consent',
      entityId: consent._id,
      newData: { applicationId, adminApproval: true },
    });

    return consent;
  }

  /**
   * Get consent record for an application.
   */
  async getByApplication(applicationId) {
    const consent = await consentRepository.findByApplication(applicationId);
    if (!consent) {
      throw ApiError.notFound(messages.CONSENT.NOT_FOUND);
    }
    return consent;
  }

  /**
   * Record user consent for an application.
   */
  async recordUserConsent(applicationId, userId) {
    const consent = await consentRepository.findByUserAndApplication(userId, applicationId);
    if (!consent) {
      throw ApiError.notFound(messages.CONSENT.NOT_FOUND);
    }

    const updated = await consentRepository.updateById(consent._id, {
      userConsent: true,
      consentTimestamp: new Date(),
    });

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.UPDATE,
      entityType: 'Consent',
      entityId: consent._id,
      newData: { userConsent: true },
    });

    return updated;
  }
}

module.exports = new ConsentService();
