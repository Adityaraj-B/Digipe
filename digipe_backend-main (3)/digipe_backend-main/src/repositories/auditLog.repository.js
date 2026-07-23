const BaseRepository = require('./base.repository');
const AuditLog = require('../models/auditLog.model');

class AuditLogRepository extends BaseRepository {
  constructor() {
    super(AuditLog);
  }

  async findByEntity(entityType, entityId, options = {}) {
    return this.findWithPagination(
      { entityType, entityId },
      { ...options, populate: { path: 'user', select: 'name mobileNumber role' } }
    );
  }

  async findByUser(userId, options = {}) {
    return this.findWithPagination(
      { user: userId },
      options
    );
  }

  async logAction({ user, action, entityType, entityId, previousData, newData, ipAddress, userAgent }) {
    return this.create({
      user,
      action,
      entityType,
      entityId,
      previousData,
      newData,
      ipAddress,
      userAgent,
    });
  }
}

module.exports = new AuditLogRepository();
