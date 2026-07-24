const BaseRepository = require('./base.repository');
const AdminPriceSettings = require('../models/adminPriceSettings.model');

class AdminPriceSettingsRepository extends BaseRepository {
  constructor() {
    super(AdminPriceSettings);
  }

  /**
   * Get the singleton price settings document.
   * Creates one with defaults if none exists.
   */
  async getSettings() {
    let settings = await this.model.findOne();
    if (!settings) {
      settings = await this.model.create({});
    }
    return settings;
  }

  /**
   * Upsert the singleton price settings document.
   */
  async upsertSettings(data) {
    return this.model.findOneAndUpdate(
      {},
      { $set: data },
      { new: true, upsert: true, runValidators: true }
    );
  }
}

module.exports = new AdminPriceSettingsRepository();
