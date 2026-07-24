const authService = require('../services/auth.service');
const asyncHandler = require('../utils/asyncHandler');
const ApiResponse = require('../utils/apiResponse');
const messages = require('../constants/messages');

const registerUser = asyncHandler(async (req, res) => {
  const { fullName, phone, email } = req.body;
  console.log(`[TRACE][controller.registerUser] ENTER — phone=${phone}, email=${email}, fullName=${fullName}`);
  const result = await authService.registerUser({ fullName, phone, email });
  console.log(`[TRACE][controller.registerUser] SUCCESS — result=${JSON.stringify(result)}`);
  return ApiResponse.ok(res, messages.AUTH.REGISTER_OTP_SENT || messages.AUTH.OTP_SENT, result);
});

const sendOtp = asyncHandler(async (req, res) => {
  const { mobileNumber, email } = req.body;
  const identifier = mobileNumber || email;
  const result = await authService.sendOtp(identifier);
  return ApiResponse.ok(res, messages.AUTH.OTP_SENT, result);
});

const verifyOtp = asyncHandler(async (req, res) => {
  const { mobileNumber, email, code } = req.body;
  const identifier = email || mobileNumber; // Prefer email (registration OTP goes to email)
  const meta = {
    ipAddress: req.ip,
    userAgent: req.get('User-Agent'),
    // Pass both identifiers so service can store phone even when verifying by email
    mobileNumber: mobileNumber || null,
    email: email || null,
  };
  console.log(`[TRACE][controller.verifyOtp] ENTER — identifier=${identifier}, mobileNumber=${mobileNumber}, email=${email}, code=${code}`);
  try {
    const result = await authService.verifyOtp(identifier, code, meta);
    console.log(`[TRACE][controller.verifyOtp] SUCCESS — userId=${result?.user?._id}, isNewUser=${result?.isNewUser}, sessionId=${result?.sessionId}`);
    const response = ApiResponse.ok(res, messages.AUTH.OTP_VERIFIED, result);
    console.log(`[TRACE][controller.verifyOtp] RESPONSE SENT — status=200, message=${messages.AUTH.OTP_VERIFIED}`);
    return response;
  } catch (err) {
    console.log(`[TRACE][controller.verifyOtp] EXCEPTION CAUGHT — name=${err.name}, message=${err.message}, statusCode=${err.statusCode}, stack=${err.stack?.split('\n').slice(0, 3).join(' | ')}`);
    throw err;
  }
});

const getProfile = asyncHandler(async (req, res) => {
  const user = await authService.getProfile(req.user._id);
  return ApiResponse.ok(res, messages.AUTH.PROFILE_FETCHED, user);
});

const updateProfile = asyncHandler(async (req, res) => {
  const user = await authService.updateProfile(req.user._id, req.body);
  return ApiResponse.ok(res, messages.AUTH.PROFILE_UPDATED, user);
});

module.exports = {
  registerUser,
  sendOtp,
  verifyOtp,
  getProfile,
  updateProfile,
};
