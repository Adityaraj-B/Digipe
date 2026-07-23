class ApiResponse {
  constructor(statusCode, message, data = null, meta = null) {
    this.success = statusCode >= 200 && statusCode < 300;
    this.statusCode = statusCode;
    this.message = message;
    this.data = data;
    if (meta) {
      this.meta = meta;
    }
  }

  static success(res, statusCode, message, data = null, meta = null) {
    const response = new ApiResponse(statusCode, message, data, meta);
    return res.status(statusCode).json(response);
  }

  static created(res, message, data = null) {
    return ApiResponse.success(res, 201, message, data);
  }

  static ok(res, message, data = null, meta = null) {
    return ApiResponse.success(res, 200, message, data, meta);
  }

  static noContent(res) {
    return res.status(204).send();
  }
}

module.exports = ApiResponse;
