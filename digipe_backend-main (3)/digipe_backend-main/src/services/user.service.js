const userRepository = require('../repositories/user.repository');
const ApiError = require('../utils/apiError');
const { buildPaginationMeta } = require('../utils/pagination');

class UserService {
  async getAllUsers(filter, options) {
    const { docs, totalDocs } = await userRepository.findWithPagination(filter, options);
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { users: docs, meta };
  }

  async getUserById(id) {
    const user = await userRepository.findById(id);
    if (!user) {
      throw ApiError.notFound('User not found');
    }
    return user;
  }

  async updateUser(id, data) {
    const user = await userRepository.updateById(id, data);
    if (!user) {
      throw ApiError.notFound('User not found');
    }
    return user;
  }

  async deactivateUser(id) {
    const user = await userRepository.updateById(id, { isActive: false });
    if (!user) {
      throw ApiError.notFound('User not found');
    }
    return user;
  }

  async activateUser(id) {
    const user = await userRepository.updateById(id, { isActive: true });
    if (!user) {
      throw ApiError.notFound('User not found');
    }
    return user;
  }
}

module.exports = new UserService();
