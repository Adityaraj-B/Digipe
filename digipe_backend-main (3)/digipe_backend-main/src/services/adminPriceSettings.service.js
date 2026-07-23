const adminPriceSettingsRepository = require('../repositories/adminPriceSettings.repository');
const auditLogService = require('./auditLog.service');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');
const { AUDIT_ACTIONS } = require('../constants');

class AdminPriceSettingsService {
  /**
   * Get current price settings.
   */
  async getSettings() {
    return adminPriceSettingsRepository.getSettings();
  }

  /**
   * Update promotional discount settings.
   */
  async updatePromotionalDiscount(data, adminUserId) {
    const updateData = {
      'promotionalDiscount.percentage': data.percentage,
      'promotionalDiscount.isActive': data.isActive,
      updatedBy: adminUserId,
    };

    const settings = await adminPriceSettingsRepository.upsertSettings(updateData);

    await auditLogService.log({
      user: adminUserId,
      action: AUDIT_ACTIONS.UPDATE,
      entityType: 'AdminPriceSettings',
      entityId: settings._id,
      newData: { promotionalDiscount: data },
    });

    return settings;
  }

  /**
   * Update tax / GST settings.
   */
  async updateTax(data, adminUserId) {
    const updateData = {
      'tax.gstPercentage': data.gstPercentage,
      updatedBy: adminUserId,
    };

    const settings = await adminPriceSettingsRepository.upsertSettings(updateData);

    await auditLogService.log({
      user: adminUserId,
      action: AUDIT_ACTIONS.UPDATE,
      entityType: 'AdminPriceSettings',
      entityId: settings._id,
      newData: { tax: data },
    });

    return settings;
  }

  /**
   * Calculate final amount after applying active discount and GST.
   * @param {number} subtotal - Base premium total
   * @returns {Object} { subtotal, discountPercentage, discountAmount, gstPercentage, taxAmount, totalAmount }
   */
  async calculateFinalAmount(subtotal) {
    const settings = await adminPriceSettingsRepository.getSettings();

    let discountPercentage = 0;
    let discountAmount = 0;
    let gstPercentage = settings.tax?.gstPercentage || 0;

    // Apply promotional discount if active
    if (settings.promotionalDiscount?.isActive && settings.promotionalDiscount?.percentage > 0) {
      discountPercentage = settings.promotionalDiscount.percentage;
      discountAmount = Math.round((subtotal * discountPercentage) / 100 * 100) / 100;
    }

    const afterDiscount = subtotal - discountAmount;

    // Apply GST on discounted amount
    const taxAmount = Math.round((afterDiscount * gstPercentage) / 100 * 100) / 100;
    const totalAmount = Math.round((afterDiscount + taxAmount) * 100) / 100;

    return {
      subtotal,
      discountPercentage,
      discountAmount,
      gstPercentage,
      taxAmount,
      totalAmount,
    };
  }
}

module.exports = new AdminPriceSettingsService();
