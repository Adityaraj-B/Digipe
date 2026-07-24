const fs = require('fs');
const cloudinary = require('../config/cloudinary');
const documentRepository = require('../repositories/document.repository');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const logger = require('../config/logger');
const { FILE_TYPES } = require('../constants');

/**
 * Detect file type from MIME type.
 */
function detectFileType(mimeType) {
  if (mimeType && mimeType.startsWith('image/')) return FILE_TYPES.IMAGE;
  if (mimeType && mimeType.startsWith('video/')) return FILE_TYPES.VIDEO;
  return FILE_TYPES.DOCUMENT;
}

/**
 * Safely delete a temporary file from disk.
 * Silently ignores errors if the file was already deleted or doesn't exist.
 * @param {string} filePath - Absolute path to the temp file
 */
function cleanupTempFile(filePath) {
  if (!filePath) return;
  try {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      logger.debug(`Temp file cleaned up: ${filePath}`);
    }
  } catch (err) {
    logger.warn(`Failed to clean up temp file ${filePath}: ${err.message}`);
  }
}

class DocumentService {
  /**
   * Upload a file to Cloudinary and save the document record.
   *
   * Uses file.path (disk storage) instead of file.buffer (memory storage)
   * so large videos don't consume Node.js heap memory.
   *
   * @param {string} userId
   * @param {Object} file - Multer file object (from disk storage, has file.path)
   * @param {string} [applicationId] - Optional application ID to link
   * @returns {Promise<Object>}
   */
  async upload(userId, file, applicationId = null) {
    if (!file) {
      throw ApiError.badRequest('No file provided');
    }

    // Guard: ensure multer actually wrote the temp file to disk
    if (!file.path) {
      logger.error('Document upload failed: file.path is undefined — multer may not have saved the file');
      throw ApiError.internal('File upload failed: temporary file was not created');
    }

    if (!fs.existsSync(file.path)) {
      logger.error(`Document upload failed: temp file does not exist at ${file.path}`);
      throw ApiError.internal('File upload failed: temporary file not found on disk');
    }

    try {
      // Determine the correct Cloudinary resource_type based on MIME type.
      // Using 'auto' can fail for certain video formats on some Cloudinary accounts,
      // so we explicitly set 'video' for video MIME types.
      const isVideo = file.mimetype && file.mimetype.startsWith('video/');
      const resourceType = isVideo ? 'video' : 'auto';

      // Upload to Cloudinary using the temp file path (not buffer).
      // This lets Cloudinary's SDK handle streaming internally without
      // loading the entire file into the Node.js heap.
      const uploadResult = await cloudinary.uploader.upload(file.path, {
        folder: 'digipe-insurance/documents',
        resource_type: resourceType,
        public_id: `${userId}_${Date.now()}`,
      });

      // Save document record — only the Cloudinary URL and metadata are stored
      const document = await documentRepository.create({
        user: userId,
        originalName: file.originalname,
        fileName: uploadResult.public_id,
        mimeType: file.mimetype,
        size: file.size,
        url: uploadResult.secure_url,
        fileType: detectFileType(file.mimetype),
        application: applicationId || null,
        cloudinaryPublicId: uploadResult.public_id,
      });

      logger.info(`Document uploaded: ${document._id} by user ${userId}`);

      return document;
    } catch (error) {
      logger.error(`Document upload failed: ${error.message}`, { stack: error.stack });
      // Surface the real error message for debugging (Cloudinary auth failures, network issues, etc.)
      throw ApiError.internal(`${messages.DOCUMENT.UPLOAD_FAILED}: ${error.message}`);
    } finally {
      // Always clean up the temporary file from disk, whether upload
      // succeeded or failed. This prevents disk space leaks.
      cleanupTempFile(file.path);
    }
  }

  /**
   * Upload multiple files to Cloudinary sequentially.
   *
   * Files are processed one-by-one to avoid excessive concurrent memory usage.
   * If any file fails, remaining unprocessed temp files are cleaned up.
   *
   * @param {string} userId
   * @param {Array<Object>} files - Array of Multer file objects (disk storage)
   * @param {string} [applicationId] - Optional application ID to link
   * @returns {Promise<Array<Object>>}
   */
  async uploadMultiple(userId, files, applicationId = null) {
    if (!files || files.length === 0) {
      throw ApiError.badRequest('No files provided');
    }

    const uploadedDocuments = [];
    const processedIndices = new Set();

    try {
      for (let i = 0; i < files.length; i++) {
        const document = await this.upload(userId, files[i], applicationId);
        uploadedDocuments.push(document);
        processedIndices.add(i);
      }

      logger.info(`${uploadedDocuments.length} documents uploaded by user ${userId}`);

      return uploadedDocuments;
    } catch (error) {
      // Clean up temp files for any remaining unprocessed files.
      // The file that failed has already been cleaned up by the upload() finally block.
      for (let i = 0; i < files.length; i++) {
        if (!processedIndices.has(i)) {
          cleanupTempFile(files[i].path);
        }
      }
      throw error;
    }
  }

  /**
   * Get document by ID.
   */
  async getById(id) {
    const document = await documentRepository.findById(id);
    if (!document) {
      throw ApiError.notFound(messages.DOCUMENT.NOT_FOUND);
    }
    return document;
  }

  /**
   * Soft-delete a document and remove from Cloudinary.
   */
  async delete(id, userId) {
    const document = await documentRepository.findById(id);
    if (!document) {
      throw ApiError.notFound(messages.DOCUMENT.NOT_FOUND);
    }

    if (document.user.toString() !== userId.toString()) {
      throw ApiError.forbidden(messages.AUTH.FORBIDDEN);
    }

    // Delete from Cloudinary
    try {
      await cloudinary.uploader.destroy(document.cloudinaryPublicId);
    } catch (error) {
      logger.warn(`Failed to delete from Cloudinary: ${document.cloudinaryPublicId} - ${error.message}`);
    }

    await documentRepository.softDelete(id);

    return { message: messages.DOCUMENT.DELETED };
  }
}

module.exports = new DocumentService();
