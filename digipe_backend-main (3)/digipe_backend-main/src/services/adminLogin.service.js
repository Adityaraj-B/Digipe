const loginLogRepository = require('../repositories/loginLog.repository');

class AdminLoginService {
  /**
   * Get paginated login audit logs.
   * @param {number} page - Page number (1-based)
   * @param {number} limit - Items per page
   * @returns {Promise<Object>} { docs, totalDocs, totalPages, currentPage, limit }
   */
  async getLogins(page = 1, limit = 5) {
    const { docs, totalDocs } = await loginLogRepository.findWithPagination(
      {},
      {
        page,
        limit,
        sort: { createdAt: -1 },
      }
    );

    const totalPages = Math.ceil(totalDocs / limit);

    return {
      logins: docs,
      totalDocs,
      totalPages,
      currentPage: page,
      limit,
    };
  }
}

module.exports = new AdminLoginService();
