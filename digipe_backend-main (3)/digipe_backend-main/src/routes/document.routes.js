const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const documentController = require('../controllers/document.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validation.middleware');
const documentValidator = require('../validators/document.validator');

// Ensure temp upload directory exists
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Multer disk storage — files are written to a temp directory, then streamed to Cloudinary.
// This avoids loading the entire file into Node.js heap memory, preventing OOM crashes
// for large video uploads and high-concurrency batch uploads.
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB max (production-grade video support)
  },
  fileFilter: (req, file, cb) => {
    const allowedMimeTypes = [
      // Images
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
      // Videos
      'video/mp4',
      'video/mpeg',
      'video/quicktime',
      'video/x-msvideo',
      'video/webm',
      'video/3gpp',
      // Documents
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ];

    if (allowedMimeTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Allowed: JPEG, PNG, GIF, WebP, MP4, MPEG, MOV, AVI, WebM, 3GP, PDF, DOC, DOCX'), false);
    }
  },
});

/**
 * @swagger
 * /api/documents/upload:
 *   post:
 *     tags: [Documents]
 *     summary: Upload a single document to Cloudinary
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required: [file]
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *                 description: File to upload (max 50MB)
 *               applicationId:
 *                 type: string
 *                 description: Optional application ID to link document
 *     responses:
 *       201:
 *         description: Document uploaded to Cloudinary
 *       400:
 *         description: No file or invalid file type
 */
router.post('/upload', authenticate, upload.single('file'), documentController.upload);

/**
 * @swagger
 * /api/documents/upload-multiple:
 *   post:
 *     tags: [Documents]
 *     summary: Upload multiple documents (images/videos) to Cloudinary
 *     description: Supports up to 20 files per request. Minimum 4 images recommended for verification.
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required: [files]
 *             properties:
 *               files:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: binary
 *                 description: Files to upload (max 50MB each, up to 20 files)
 *               applicationId:
 *                 type: string
 *                 description: Optional application ID to link documents
 *     responses:
 *       201:
 *         description: Documents uploaded to Cloudinary
 *       400:
 *         description: No files or invalid file type
 */
router.post('/upload-multiple', authenticate, upload.array('files', 20), documentController.uploadMultiple);

/**
 * @swagger
 * /api/documents/{id}:
 *   get:
 *     tags: [Documents]
 *     summary: Get document details
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Document details with Cloudinary URL
 */
router.get('/:id', authenticate, validate(documentValidator.getDocument), documentController.getById);

/**
 * @swagger
 * /api/documents/{id}:
 *   delete:
 *     tags: [Documents]
 *     summary: Delete a document (soft delete + Cloudinary removal)
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Document deleted
 */
router.delete('/:id', authenticate, validate(documentValidator.deleteDocument), documentController.remove);

module.exports = router;
