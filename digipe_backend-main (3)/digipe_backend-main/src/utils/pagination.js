/**
 * Parse pagination, sorting, and filtering parameters from request query.
 *
 * @param {Object} query - Express req.query object
 * @param {Array<string>} allowedFilters - List of field names allowed for filtering
 * @returns {Object} { filter, options: { page, limit, skip, sort } }
 */
const parsePaginationQuery = (query, allowedFilters = []) => {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || 10));
  const skip = (page - 1) * limit;

  // Sorting: ?sort=name or ?sort=-createdAt (prefix - for desc)
  let sort = { createdAt: -1 }; // default newest first
  if (query.sort) {
    const sortFields = query.sort.split(',');
    sort = {};
    sortFields.forEach((field) => {
      if (field.startsWith('-')) {
        sort[field.substring(1)] = -1;
      } else {
        sort[field] = 1;
      }
    });
  }

  // Filtering: only allow specified filter fields
  const filter = {};
  allowedFilters.forEach((key) => {
    if (query[key] !== undefined && query[key] !== '') {
      filter[key] = query[key];
    }
  });

  // Search: ?search=term (searches name fields)
  if (query.search) {
    filter.$or = [
      { name: { $regex: query.search, $options: 'i' } },
      { description: { $regex: query.search, $options: 'i' } },
    ];
  }

  return {
    filter,
    options: {
      page,
      limit,
      skip,
      sort,
    },
  };
};

/**
 * Build pagination metadata for API response.
 *
 * @param {number} totalDocs - Total number of matching documents
 * @param {number} page - Current page number
 * @param {number} limit - Items per page
 * @returns {Object} Pagination metadata
 */
const buildPaginationMeta = (totalDocs, page, limit) => {
  const totalPages = Math.ceil(totalDocs / limit);

  return {
    totalDocs,
    totalPages,
    currentPage: page,
    limit,
    hasNextPage: page < totalPages,
    hasPrevPage: page > 1,
  };
};

module.exports = {
  parsePaginationQuery,
  buildPaginationMeta,
};
