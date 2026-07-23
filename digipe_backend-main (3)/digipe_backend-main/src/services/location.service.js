const geoip = require('geoip-lite');
const User = require('../models/user.model');
const logger = require('../config/logger');
const ApiError = require('../utils/apiError');
const messages = require('../constants/messages');

/**
 * Updates a user's location coordinates and reverse-geocodes to city/state.
 * Uses geoip-lite for IP-based fallback, but primarily accepts GPS coordinates
 * from the frontend.
 *
 * @param {string} userId - The user's MongoDB ID
 * @param {number} latitude - GPS latitude
 * @param {number} longitude - GPS longitude
 * @returns {Object} Updated user location
 */
const updateUserLocation = async (userId, latitude, longitude) => {
  // Validate coordinates
  if (
    typeof latitude !== 'number' || typeof longitude !== 'number' ||
    latitude < -90 || latitude > 90 ||
    longitude < -180 || longitude > 180
  ) {
    throw ApiError.badRequest(messages.LOCATION.INVALID_COORDINATES);
  }

  // Attempt reverse geocoding via geoip-lite (works for approximate city detection)
  // For production, consider using Google Maps Geocoding API for precise results
  let city = null;
  let state = null;

  try {
    // geoip-lite doesn't do reverse geocoding from lat/lng, but we can use it as
    // a fallback from IP. For lat/lng, we'll store coordinates and use a simple
    // city mapping based on known Indian city coordinate ranges.
    const cityInfo = getCityFromCoordinates(latitude, longitude);
    city = cityInfo.city;
    state = cityInfo.state;
  } catch (error) {
    logger.warn(`Reverse geocoding failed for (${latitude}, ${longitude}): ${error.message}`);
  }

  const user = await User.findByIdAndUpdate(
    userId,
    {
      $set: {
        'location.type': 'Point',
        'location.coordinates': [longitude, latitude], // GeoJSON is [lng, lat]
        'location.city': city,
        'location.state': state,
        'location.lastUpdated': new Date(),
      },
    },
    { new: true }
  );

  logger.info(`Updated location for user ${userId}: city=${city}, state=${state}`);

  return {
    coordinates: { latitude, longitude },
    city,
    state,
    lastUpdated: user.location.lastUpdated,
  };
};

/**
 * Resolves city/state from latitude & longitude using IP-based lookup as fallback.
 * For production use, integrate Google Maps Geocoding API.
 *
 * @param {string} ip - Client IP address
 * @returns {{ city: string|null, state: string|null }}
 */
const getCityFromIP = (ip) => {
  const geo = geoip.lookup(ip);
  if (geo) {
    return { city: geo.city || null, state: geo.region || null };
  }
  return { city: null, state: null };
};

/**
 * Simple city detection from coordinates for major Indian cities.
 * For production, use a proper geocoding API (Google Maps, OpenCage, etc.)
 */
const getCityFromCoordinates = (lat, lng) => {
  const cities = [
    { name: 'Mumbai', state: 'Maharashtra', lat: 19.076, lng: 72.8777, radius: 0.5 },
    { name: 'Delhi', state: 'Delhi', lat: 28.6139, lng: 77.209, radius: 0.5 },
    { name: 'Bangalore', state: 'Karnataka', lat: 12.9716, lng: 77.5946, radius: 0.5 },
    { name: 'Hyderabad', state: 'Telangana', lat: 17.385, lng: 78.4867, radius: 0.5 },
    { name: 'Chennai', state: 'Tamil Nadu', lat: 13.0827, lng: 80.2707, radius: 0.5 },
    { name: 'Kolkata', state: 'West Bengal', lat: 22.5726, lng: 88.3639, radius: 0.5 },
    { name: 'Pune', state: 'Maharashtra', lat: 18.5204, lng: 73.8567, radius: 0.5 },
    { name: 'Ahmedabad', state: 'Gujarat', lat: 23.0225, lng: 72.5714, radius: 0.5 },
    { name: 'Jaipur', state: 'Rajasthan', lat: 26.9124, lng: 75.7873, radius: 0.5 },
    { name: 'Lucknow', state: 'Uttar Pradesh', lat: 26.8467, lng: 80.9462, radius: 0.5 },
    { name: 'Chandigarh', state: 'Chandigarh', lat: 30.7333, lng: 76.7794, radius: 0.4 },
    { name: 'Indore', state: 'Madhya Pradesh', lat: 22.7196, lng: 75.8577, radius: 0.4 },
    { name: 'Nagpur', state: 'Maharashtra', lat: 21.1458, lng: 79.0882, radius: 0.4 },
    { name: 'Surat', state: 'Gujarat', lat: 21.1702, lng: 72.8311, radius: 0.4 },
    { name: 'Kochi', state: 'Kerala', lat: 9.9312, lng: 76.2673, radius: 0.4 },
    { name: 'Bhopal', state: 'Madhya Pradesh', lat: 23.2599, lng: 77.4126, radius: 0.4 },
    { name: 'Coimbatore', state: 'Tamil Nadu', lat: 11.0168, lng: 76.9558, radius: 0.4 },
    { name: 'Visakhapatnam', state: 'Andhra Pradesh', lat: 17.6868, lng: 83.2185, radius: 0.4 },
    { name: 'Gurgaon', state: 'Haryana', lat: 28.4595, lng: 77.0266, radius: 0.3 },
    { name: 'Noida', state: 'Uttar Pradesh', lat: 28.5355, lng: 77.391, radius: 0.3 },
  ];

  for (const city of cities) {
    const distance = Math.sqrt(
      Math.pow(lat - city.lat, 2) + Math.pow(lng - city.lng, 2)
    );
    if (distance <= city.radius) {
      return { city: city.name, state: city.state };
    }
  }

  return { city: null, state: null };
};

/**
 * Get all users in a specific city who have opted in for coupon notifications.
 *
 * @param {string} city - City name
 * @returns {Array} Users with push tokens
 */
const getUsersInCity = async (city) => {
  return User.find({
    'location.city': city,
    'notificationPreferences.coupons': true,
    'pushTokens.0': { $exists: true }, // has at least one push token
    isActive: true,
    isDeleted: false,
  }).select('_id name pushTokens location.city');
};

/**
 * Register a push notification token for a user.
 *
 * @param {string} userId - The user's MongoDB ID
 * @param {string} token - FCM device token
 * @param {string} platform - 'web', 'android', or 'ios'
 */
const registerPushToken = async (userId, token, platform = 'web') => {
  // Avoid duplicates
  await User.findByIdAndUpdate(userId, {
    $pull: { pushTokens: { token } },
  });

  await User.findByIdAndUpdate(userId, {
    $push: {
      pushTokens: { token, platform, createdAt: new Date() },
    },
  });

  logger.info(`Registered push token for user ${userId} (platform: ${platform})`);
};

/**
 * Remove a push notification token for a user.
 */
const removePushToken = async (userId, token) => {
  await User.findByIdAndUpdate(userId, {
    $pull: { pushTokens: { token } },
  });

  logger.info(`Removed push token for user ${userId}`);
};

module.exports = {
  updateUserLocation,
  getCityFromIP,
  getCityFromCoordinates,
  getUsersInCity,
  registerPushToken,
  removePushToken,
};
