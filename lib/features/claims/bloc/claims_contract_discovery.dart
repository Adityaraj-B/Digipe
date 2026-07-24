import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';

/// Utility to perform a trial claim submission and capture the server's contract requirements.
class ClaimsContractDiscovery {
  final ApiService _apiService;

  ClaimsContractDiscovery(this._apiService);

  Future<void> runTrialSubmission(String orderId) async {
    dev.log('Starting Claims Contract Discovery for Order: $orderId');
    
    try {
      // Step 7: We send a minimal/guessed body matching the NEW submitClaim signature
      await _apiService.submitClaim(
        policyId: orderId,
        description: 'Trial submission to discover contract',
        claimAmount: 1, // Minimal amount to trigger validation
      );
      dev.log('SUCCESS: Claim submitted with guessed body. Contract confirmed.');
    } on DioException catch (e) {
      dev.log('CONTRACT DISCOVERED: Server rejected trial body.');
      dev.log('Status Code: ${e.response?.statusCode}');
      dev.log('Response Body: ${e.response?.data}');
    } catch (e) {
      dev.log('Discovery failed with unexpected error: $e');
    }
  }
}
