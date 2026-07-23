const auditLogRepository = require('../repositories/auditLog.repository');
const logger = require('../config/logger');

class AuditLogService {
  /**
   * Create an audit log entry. Non-blocking — errors are logged but not thrown.
   */
  async log({ user, action, entityType, entityId, previousData = null, newData = null, ipAddress = null, userAgent = null }) {
    try {
      await auditLogRepository.logAction({
        user,
        action,
        entityType,
        entityId,
        previousData,
        newData,
        ipAddress,
        userAgent,
      });
    } catch (error) {
      logger.error(`Audit log failed: ${error.message}`, {
        action,
        entityType,
        entityId,
      });
    }
  }

  /**
   * Get audit logs for a specific entity.
   */
  async getByEntity(entityType, entityId, options = {}) {
    return auditLogRepository.findByEntity(entityType, entityId, options);
  }

  /**
   * Get audit logs by user.
   */
  async getByUser(userId, options = {}) {
    return auditLogRepository.findByUser(userId, options);
  }
}

module.exports = new AuditLogService();
