import 'dart:async';
import '../../features/claims/bloc/claims_bloc.dart';

class ClaimsRepository {
  Future<ClaimsData> fetchClaimsData(List<String> activePolicyNames) async {
    await Future.delayed(const Duration(seconds: 1));
    
    return ClaimsData(
      eligiblePolicies: activePolicyNames.map((name) => PolicyItem(id: name, name: name)).toList(),
      claimHistory: [
        ClaimHistoryItem(
          claimId: 'CLM-9A882C11',
          policyName: 'amit yadssv',
          date: 'May 10, 2026',
          status: 'Pending',
        ),
      ],
    );
  }

  Future<void> submitClaim(String policyId, String details) async {
    await Future.delayed(const Duration(seconds: 2));
    // In a real app, this would hit the API and update the list
  }
}
