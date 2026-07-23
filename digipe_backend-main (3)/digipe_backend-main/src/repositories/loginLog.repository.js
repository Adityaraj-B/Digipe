const BaseRepository = require('./base.repository');
const LoginLog = require('../models/loginLog.model');

class LoginLogRepository extends BaseRepository {
  constructor() {
    super(LoginLog);
  }
}

module.exports = new LoginLogRepository();
