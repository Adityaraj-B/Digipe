import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/claims_repository.dart';
import '../../../core/repositories/orders_repository.dart';

class PolicyItem {
  final String id;
  final String name;

  PolicyItem({
    required this.id,
    required this.name,
  });
}

class ClaimHistoryItem {
  final String claimId;
  final String policyName;
  final String date;
  final String status;

  ClaimHistoryItem({
    required this.claimId,
    required this.policyName,
    required this.date,
    required this.status,
  });
}

class ClaimsData {
  final List<PolicyItem> eligiblePolicies;
  final List<ClaimHistoryItem> claimHistory;

  ClaimsData({
    required this.eligiblePolicies,
    required this.claimHistory,
  });
}

abstract class ClaimsEvent {}

class FetchClaimsData extends ClaimsEvent {}

class SubmitClaimEvent extends ClaimsEvent {
  final String policyId;
  final String incidentDate;
  final String description;
  final List<String> evidencePaths;

  SubmitClaimEvent({
    required this.policyId,
    required this.incidentDate,
    required this.description,
    required this.evidencePaths,
  });
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

class ClaimsBloc extends Bloc<ClaimsEvent, ClaimsState> {
  final ClaimsRepository _claimsRepository;
  final OrdersRepository _ordersRepository;

  ClaimsBloc({
    required ClaimsRepository claimsRepository,
    required OrdersRepository ordersRepository,
  })  : _claimsRepository = claimsRepository,
        _ordersRepository = ordersRepository,
        super(ClaimsInitial()) {
    on<FetchClaimsData>(_onFetchData);
    on<SubmitClaimEvent>(_onSubmitClaim);
  }

  Future<void> _onFetchData(
      FetchClaimsData event,
      Emitter<ClaimsState> emit,
      ) async {
    emit(ClaimsLoading());
    try {
      final orders = await _ordersRepository.fetchOrders();
      final activePolicyNames = orders
          .where((o) => o.status == 'Active')
          .map((o) => o.product)
          .toList();

      final data = await _claimsRepository.fetchClaimsData(activePolicyNames);
      emit(ClaimsLoaded(data));
    } catch (e) {
      emit(ClaimsError('Failed to load claims data.'));
    }
  }

  Future<void> _onSubmitClaim(
      SubmitClaimEvent event,
      Emitter<ClaimsState> emit,
      ) async {
    emit(ClaimSubmitting());
    try {
      await _claimsRepository.submitClaim(event.policyId, event.description);
      emit(ClaimSubmitSuccess());
      add(FetchClaimsData());
    } catch (e) {
      emit(ClaimsError('Failed to submit claim.'));
    }
  }
}
