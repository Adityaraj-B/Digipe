const documentService = require('../services/document.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');

const upload = asyncHandler(async (req, res) => {
  const document = await documentService.upload(req.user._id, req.file, req.body.applicationId || null);
  return ApiResponse.created(res, messages.DOCUMENT.UPLOADED, document);
});

const uploadMultiple = asyncHandler(async (req, res) => {
  const documents = await documentService.uploadMultiple(
    req.user._id,
    req.files,
    req.body.applicationId || null
  );
  return ApiResponse.created(res, messages.DOCUMENT.UPLOADED, documents);
});

const getById = asyncHandler(async (req, res) => {
  const document = await documentService.getById(req.params.id);
  return ApiResponse.ok(res, messages.DOCUMENT.FETCHED, document);
});

const remove = asyncHandler(async (req, res) => {
  const result = await documentService.delete(req.params.id, req.user._id);
  return ApiResponse.ok(res, result.message);
});

module.exports = {
  upload,
  uploadMultiple,
  getById,
  remove,
};
