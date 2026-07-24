const BaseRepository = require('./base.repository');
const UserSession = require('../models/userSession.model');

class UserSessionRepository extends BaseRepository {
  constructor() {
    super(UserSession);
  }

  async findActiveSessionsByUser(userId) {
    return this.model.find({ user: userId, isActive: true });
  }

  async findByToken(token) {
    return this.model.findOne({ token, isActive: true });
  }

  async deactivateAllUserSessions(userId) {
    return this.model.updateMany({ user: userId, isActive: true }, { $set: { isActive: false } });
  }

  async deactivateSession(sessionId) {
    return this.model.findByIdAndUpdate(sessionId, { $set: { isActive: false } }, { new: true });
  }
}

module.exports = new UserSessionRepository();
