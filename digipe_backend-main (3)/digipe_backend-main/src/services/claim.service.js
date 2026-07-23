const claimRepository = require('../repositories/claim.repository');
const claimDocumentRepository = require('../repositories/claimDocument.repository');
const policyRepository = require('../repositories/policy.repository');
const documentRepository = require('../repositories/document.repository');
const auditLogService = require('./auditLog.service');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const { generateClaimNumber } = require('../utils/helpers');
const { buildPaginationMeta } = require('../utils/pagination');
const { AUDIT_ACTIONS, CLAIM_STATUS, POLICY_STATUS } = require('../constants');

class ClaimService {
  /**
   * Submit a new claim against an active policy.
   * Supports reason, incidentDate, images[], and videos[].
   */
  async create(userId, data) {
    const policy = await policyRepository.findById(data.policyId);
    if (!policy) {
      throw ApiError.notFound(messages.POLICY.NOT_FOUND);
    }

    if (policy.user.toString() !== userId.toString()) {
      throw ApiError.forbidden(messages.AUTH.FORBIDDEN);
    }

    if (policy.status !== POLICY_STATUS.ACTIVE) {
      throw ApiError.badRequest(messages.CLAIM.POLICY_NOT_ACTIVE);
    }

    // Check for existing active claim
    const existingClaim = await claimRepository.findActiveByPolicy(data.policyId);
    if (existingClaim) {
      throw ApiError.conflict(messages.CLAIM.ALREADY_CLAIMED);
    }

    const claim = await claimRepository.create({
      user: userId,
      policy: data.policyId,
      claimNumber: generateClaimNumber(),
      description: data.description,
      reason: data.reason || null,
      incidentDate: data.incidentDate || null,
      claimAmount: data.claimAmount,
      status: CLAIM_STATUS.SUBMITTED,
    });

    // Auto-link uploaded images as claim documents
    const allDocIds = [];
    if (data.images && Array.isArray(data.images) && data.images.length > 0) {
      for (const docId of data.images) {
        const doc = await documentRepository.findById(docId);
        if (doc) {
          allDocIds.push({ claim: claim._id, document: docId, documentType: 'PHOTO' });
        }
      }
    }

    // Auto-link uploaded videos as claim documents
    if (data.videos && Array.isArray(data.videos) && data.videos.length > 0) {
      for (const docId of data.videos) {
        const doc = await documentRepository.findById(docId);
        if (doc) {
          allDocIds.push({ claim: claim._id, document: docId, documentType: 'OTHER' });
        }
      }
    }

    if (allDocIds.length > 0) {
      await claimDocumentRepository.createMany(allDocIds);
    }

    await auditLogService.log({
      user: userId,
      action: AUDIT_ACTIONS.CREATE,
      entityType: 'Claim',
      entityId: claim._id,
      newData: {
        claimNumber: claim.claimNumber,
        claimAmount: data.claimAmount,
        reason: data.reason,
        incidentDate: data.incidentDate,
        imagesCount: data.images?.length || 0,
        videosCount: data.videos?.length || 0,
      },
    });

    return claimRepository.findByIdWithDetails(claim._id);
  }

  /**
   * Get customer's claims with pagination.
   */
  async getMyClaims(userId, options) {
    const { docs, totalDocs } = await claimRepository.findByUser(userId, options);
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { claims: docs, meta };
  }

  /**
   * Get all claims (admin) with pagination.
   */
  async getAll(filter, options) {
    const { docs, totalDocs } = await claimRepository.findWithPagination(filter, {
      ...options,
      populate: [
        { path: 'user', select: 'name mobileNumber email' },
        { path: 'policy', select: 'policyNumber coverageAmount status' },
      ],
    });
    const meta = buildPaginationMeta(totalDocs, options.page, options.limit);
    return { claims: docs, meta };
  }

  /**
   * Get a single claim by ID with full details.
   */
  async getById(id) {
    const claim = await claimRepository.findByIdWithDetails(id);
    if (!claim) {
      throw ApiError.notFound(messages.CLAIM.NOT_FOUND);
    }
    return claim;
  }

  /**
   * Add a document to a claim.
   */
  async addDocument(claimId, data, userId) {
    const claim = await claimRepository.findById(claimId);
    if (!claim) {
      throw ApiError.notFound(messages.CLAIM.NOT_FOUND);
    }

    if (claim.user.toString() !== userId.toString()) {
      throw ApiError.forbidden(messages.AUTH.FORBIDDEN);
    }

    const document = await documentRepository.findById(data.documentId);
    if (!document) {
      throw ApiError.notFound(messages.DOCUMENT.NOT_FOUND);
    }

    const claimDoc = await claimDocumentRepository.create({
      claim: claimId,
      document: data.documentId,
      documentType: data.documentType || 'OTHER',
    });

    return claimDoc;
  }

  /**
   * Update claim status (admin action).
   */
  async updateStatus(id, statusData, adminUserId) {
    const claim = await claimRepository.findById(id);
    if (!claim) {
      throw ApiError.notFound(messages.CLAIM.NOT_FOUND);
    }

    const previousStatus = claim.status;
    const updateData = {
      status: statusData.status,
      remarks: statusData.remarks || null,
      reviewedBy: adminUserId,
      reviewedAt: new Date(),
    };

    // If settled, add settled amount and date
    if (statusData.status === CLAIM_STATUS.SETTLED) {
      updateData.settledAmount = statusData.settledAmount || claim.claimAmount;
      updateData.settledAt = new Date();

      // Update policy status to CLAIMED
      await policyRepository.updateById(claim.policy, { status: POLICY_STATUS.CLAIMED });
    }

    const updated = await claimRepository.updateById(id, updateData);

    await auditLogService.log({
      user: adminUserId,
      action: AUDIT_ACTIONS.STATUS_CHANGE,
      entityType: 'Claim',
      entityId: id,
      previousData: { status: previousStatus },
      newData: { status: statusData.status, remarks: statusData.remarks },
    });

    return updated;
  }
}

module.exports = new ClaimService();
