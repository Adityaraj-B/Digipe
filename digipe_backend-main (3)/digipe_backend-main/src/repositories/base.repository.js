/**
 * Base Repository — provides generic CRUD operations with pagination,
 * filtering, sorting, and soft-delete for any Mongoose model.
 */
class BaseRepository {
  /**
   * @param {import('mongoose').Model} model - Mongoose model
   */
  constructor(model) {
    this.model = model;
  }

  /**
   * Create a new document.
   * @param {Object} data
   * @returns {Promise<Object>}
   */
  async create(data) {
    const document = await this.model.create(data);
    return document;
  }

  /**
   * Create multiple documents.
   * @param {Array<Object>} dataArray
   * @returns {Promise<Array<Object>>}
   */
  async createMany(dataArray) {
    const documents = await this.model.insertMany(dataArray);
    return documents;
  }

  /**
   * Find a document by ID.
   * @param {string} id
   * @param {Object} [populateOptions] - Mongoose populate options
   * @returns {Promise<Object|null>}
   */
  async findById(id, populateOptions = null) {
    let query = this.model.findById(id);
    if (populateOptions) {
      query = query.populate(populateOptions);
    }
    return query.exec();
  }

  /**
   * Find a single document by filter.
   * @param {Object} filter
   * @param {Object} [populateOptions]
   * @returns {Promise<Object|null>}
   */
  async findOne(filter, populateOptions = null) {
    let query = this.model.findOne(filter);
    if (populateOptions) {
      query = query.populate(populateOptions);
    }
    return query.exec();
  }

  /**
   * Find all documents matching filter with pagination, sorting.
   * @param {Object} filter - MongoDB filter
   * @param {Object} options - { skip, limit, sort, populate, select }
   * @returns {Promise<Array<Object>>}
   */
  async findAll(filter = {}, options = {}) {
    const { skip = 0, limit = 10, sort = { createdAt: -1 }, populate = null, select = null } = options;

    let query = this.model
      .find(filter)
      .sort(sort)
      .skip(skip)
      .limit(limit);

    if (select) {
      query = query.select(select);
    }

    if (populate) {
      query = query.populate(populate);
    }

    return query.exec();
  }

  /**
   * Count documents matching filter.
   * @param {Object} filter
   * @returns {Promise<number>}
   */
  async count(filter = {}) {
    return this.model.countDocuments(filter);
  }

  /**
   * Check if a document exists.
   * @param {Object} filter
   * @returns {Promise<boolean>}
   */
  async exists(filter) {
    const doc = await this.model.exists(filter);
    return !!doc;
  }

  /**
   * Update a document by ID.
   * @param {string} id
   * @param {Object} updateData
   * @param {Object} [options] - Mongoose findByIdAndUpdate options
   * @returns {Promise<Object|null>}
   */
  async updateById(id, updateData, options = {}) {
    return this.model.findByIdAndUpdate(
      id,
      { $set: updateData },
      { new: true, runValidators: true, ...options }
    );
  }

  /**
   * Update a single document by filter.
   * @param {Object} filter
   * @param {Object} updateData
   * @returns {Promise<Object|null>}
   */
  async updateOne(filter, updateData) {
    return this.model.findOneAndUpdate(
      filter,
      { $set: updateData },
      { new: true, runValidators: true }
    );
  }

  /**
   * Soft delete a document by ID.
   * @param {string} id
   * @returns {Promise<Object|null>}
   */
  async softDelete(id) {
    return this.model.findByIdAndUpdate(
      id,
      { $set: { isDeleted: true, deletedAt: new Date() } },
      { new: true }
    );
  }

  /**
   * Hard delete a document by ID.
   * @param {string} id
   * @returns {Promise<Object|null>}
   */
  async hardDelete(id) {
    return this.model.findByIdAndDelete(id);
  }

  /**
   * Delete many documents matching filter.
   * @param {Object} filter
   * @returns {Promise<Object>}
   */
  async deleteMany(filter) {
    return this.model.deleteMany(filter);
  }

  /**
   * Find documents with pagination metadata.
   * @param {Object} filter
   * @param {Object} options - { page, limit, sort, populate, select }
   * @returns {Promise<{ docs: Array, totalDocs: number }>}
   */
  async findWithPagination(filter = {}, options = {}) {
    const { page = 1, limit = 10, sort = { createdAt: -1 }, populate = null, select = null } = options;
    const skip = (page - 1) * limit;

    const [docs, totalDocs] = await Promise.all([
      this.findAll(filter, { skip, limit, sort, populate, select }),
      this.count(filter),
    ]);

    return { docs, totalDocs };
  }
}

module.exports = BaseRepository;
