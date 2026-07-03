import 'dart:developer' as dev;
import '../../../../core/services/api_service.dart';

/// Utility to verify the 2-step application submission logic.
class SubmissionVerification {
  final ApiService _apiService;

  SubmissionVerification(this._apiService);

  Future<void> verifyFlow(String dummyFilePath, String planId, String fieldId) async {
    dev.log('STEP 1: Verifying Document Upload...');
    try {
      final doc = await _apiService.uploadDocumentFull(dummyFilePath);
      final id = doc['_id'] ?? doc['id'];
      dev.log('UPLOAD SUCCESS: Received ID: $id');
      
      dev.log('STEP 2: Verifying Application JSON Submission...');
      // Corrected shape: planId and fieldValues array (Step 1)
      final fieldValues = [
        {
          'productField': fieldId,
          'fieldName': 'invoice',
          'fieldValue': id, 
        },
        {
          'productField': 'some_other_field_id',
          'fieldName': 'fullName',
          'fieldValue': 'Verification Test',
        }
      ];

      final submissionBody = {
        'planId': planId,
        'fieldValues': fieldValues,
      };
      
      final response = await _apiService.submitApplication(submissionBody);
      dev.log('SUBMISSION SUCCESS: Response: $response');
    } catch (e) {
      dev.log('VERIFICATION FAILED: $e');
    }
  }
}
