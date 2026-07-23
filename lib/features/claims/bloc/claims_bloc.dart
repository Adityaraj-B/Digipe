import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';

class ClaimsBloc extends Bloc<ClaimsEvent, ClaimsState> {
  final ApiService _apiService;

  ClaimsBloc({required ApiService apiService})
      : _apiService = apiService,
        super(ClaimsInitial()) {
    on<FetchClaimsData>(_onFetchData);
    on<SubmitClaimEvent>(_onSubmitClaim);
    on<UpdateClaimStatusEvent>(_onUpdateStatus);
    on<ClearClaimsEvent>((event, emit) => emit(ClaimsInitial()));
  }

  Future<void> _onFetchData(
      FetchClaimsData event, Emitter<ClaimsState> emit) async {
    emit(ClaimsLoading());
    try {
      final policies = await _apiService.getMyPolicies();
      final activePolicies =
          policies.where((o) => o.status == 'ACTIVE').toList();

      final claimsData = await _apiService.getMyClaims();

      final data = ClaimsData(
        eligiblePolicies: activePolicies
            .map((p) => PolicyItem(id: p.orderId, name: p.product))
            .toList(),
        claimHistory: claimsData
            .map((c) => ClaimHistoryItem(
                  claimId: c['claimNumber'] ?? c['_id'] ?? '',
                  policyName:
                      c['policy']?['policyNumber'] ?? c['productName'] ?? '',
                  date: c['createdAt'] ?? '',
                  status: _displayStatus(c['status'] ?? ''),
                ))
            .toList(),
      );
      emit(ClaimsLoaded(data));
    } catch (e) {
      emit(ClaimsError('Failed to load claims: $e'));
    }
  }

  String _displayStatus(String raw) {
    switch (raw) {
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
        return 'Pending';
      case 'APPROVED':
      case 'SETTLED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        return raw;
    }
  }

  Future<void> _onSubmitClaim(
      SubmitClaimEvent event, Emitter<ClaimsState> emit) async {
    emit(ClaimSubmitting());
    try {
      await _apiService.submitClaim(
        policyId: event.policyId,
        description: event.description,
        claimAmount: event.claimAmount,
        reason: event.typeOfDamage,
        incidentDate: event.incidentDate?.toIso8601String(),
        imageDocIds: event.imageIds,
        videoDocIds: event.videoIds,
      );
      emit(ClaimSubmitSuccess());
      add(FetchClaimsData());
    } on DioException catch (e) {
      String msg = 'Claim submission failed';
      if (e.response?.statusCode == 400) {
        msg = "Only active policies can have claims filed against them.";
      } else if (e.response?.statusCode == 409) {
        msg = "A claim already exists for this policy.";
      } else {
        msg = e.response?.data?['message'] ?? msg;
      }
      emit(ClaimsError(msg));
    } catch (e) {
      emit(ClaimsError('Submission failed: $e'));
    }
  }

  Future<void> _onUpdateStatus(
      UpdateClaimStatusEvent event, Emitter<ClaimsState> emit) async {
    try {
      await _apiService.updateClaimStatus(
        event.id,
        status: event.status,
        remarks: event.remarks,
        settledAmount: event.settledAmount,
      );
      add(FetchClaimsData());
    } catch (e) {
      emit(ClaimsError('Status update failed: $e'));
    }
  }
}

abstract class ClaimsEvent {}

class FetchClaimsData extends ClaimsEvent {}

class ClearClaimsEvent extends ClaimsEvent {}

class SubmitClaimEvent extends ClaimsEvent {
  final String policyId;
  final DateTime? incidentDate;
  final String? typeOfDamage;
  final String description;
  final num claimAmount;
  final List<String> imageIds;
  final List<String> videoIds;

  SubmitClaimEvent({
    required this.policyId,
    required this.description,
    required this.claimAmount,
    this.incidentDate,
    this.typeOfDamage,
    this.imageIds = const [],
    this.videoIds = const [],
  });
}

class UpdateClaimStatusEvent extends ClaimsEvent {
  final String id;
  final String status;
  final String? remarks;
  final num? settledAmount;
  UpdateClaimStatusEvent(
      {required this.id,
      required this.status,
      this.remarks,
      this.settledAmount});
}

abstract class ClaimsState {}

class ClaimsInitial extends ClaimsState {}

class ClaimsLoading extends ClaimsState {}

class ClaimsLoaded extends ClaimsState {
  final ClaimsData data;
  ClaimsLoaded(this.data);
}

class ClaimSubmitting extends ClaimsState {}

class ClaimSubmitSuccess extends ClaimsState {}

class ClaimsError extends ClaimsState {
  final String message;
  ClaimsError(this.message);
}

class ClaimsData {
  final List<PolicyItem> eligiblePolicies;
  final List<ClaimHistoryItem> claimHistory;
  ClaimsData({required this.eligiblePolicies, required this.claimHistory});
}

class PolicyItem {
  final String id;
  final String name;
  PolicyItem({required this.id, required this.name});
}

class ClaimHistoryItem {
  final String claimId;
  final String policyName;
  final String date;
  final String status;
  ClaimHistoryItem(
      {required this.claimId,
      required this.policyName,
      required this.date,
      required this.status});
}
