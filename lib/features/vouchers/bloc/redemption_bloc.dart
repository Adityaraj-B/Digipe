import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/voucher_models.dart';
import '../services/voucher_service.dart';

// Events
abstract class RedemptionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PlaceVoucherOrder extends RedemptionEvent {
  final String productId;
  final List<Map<String, dynamic>> denominationDetails;

  PlaceVoucherOrder({required this.productId, required this.denominationDetails});

  @override
  List<Object?> get props => [productId, denominationDetails];
}

class _UpdateRedemptionResult extends RedemptionEvent {
  final VoucherOrderResult result;
  _UpdateRedemptionResult(this.result);

  @override
  List<Object?> get props => [result];
}

class _RedemptionPollingTimeout extends RedemptionEvent {}

class ResetRedemption extends RedemptionEvent {}

// States
abstract class RedemptionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RedemptionInitial extends RedemptionState {}

class RedemptionPlacingOrder extends RedemptionState {}

class RedemptionProcessing extends RedemptionState {
  final String orderId;
  final int attempt;
  RedemptionProcessing(this.orderId, {this.attempt = 0});

  @override
  List<Object?> get props => [orderId, attempt];
}

class RedemptionSuccess extends RedemptionState {
  final VoucherOrderResult result;
  RedemptionSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class RedemptionFailed extends RedemptionState {
  final String message;
  RedemptionFailed(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class RedemptionBloc extends Bloc<RedemptionEvent, RedemptionState> {
  final VoucherService _voucherService;
  Timer? _pollingTimer;

  RedemptionBloc({required VoucherService voucherService})
      : _voucherService = voucherService,
        super(RedemptionInitial()) {
    on<PlaceVoucherOrder>(_onPlaceOrder);
    on<_UpdateRedemptionResult>(_onUpdateResult);
    on<_RedemptionPollingTimeout>(_onPollingTimeout);
    on<ResetRedemption>(_onReset);
  }

  Future<void> _onPlaceOrder(PlaceVoucherOrder event, Emitter<RedemptionState> emit) async {
    emit(RedemptionPlacingOrder());
    try {
      final result = await _voucherService.redeemVoucher(
        productId: event.productId,
        denominationDetails: event.denominationDetails,
      );

      if (result.status == VoucherOrderStatus.success) {
        emit(RedemptionSuccess(result));
      } else if (result.status == VoucherOrderStatus.failed) {
        emit(RedemptionFailed(result.failureReason ?? 'Redemption failed.'));
      } else {
        emit(RedemptionProcessing(result.orderId));
        _startPolling(result.orderId);
      }
    } catch (e) {
      emit(RedemptionFailed('Could not process your request. Please try again.'));
    }
  }

  void _onUpdateResult(_UpdateRedemptionResult event, Emitter<RedemptionState> emit) {
    if (event.result.status == VoucherOrderStatus.success) {
      _stopPolling();
      emit(RedemptionSuccess(event.result));
    } else if (event.result.status == VoucherOrderStatus.failed) {
      _stopPolling();
      emit(RedemptionFailed(event.result.failureReason ?? 'Redemption failed.'));
    } else if (state is RedemptionProcessing) {
      final s = state as RedemptionProcessing;
      emit(RedemptionProcessing(s.orderId, attempt: s.attempt + 1));
    }
  }

  void _onPollingTimeout(_RedemptionPollingTimeout event, Emitter<RedemptionState> emit) {
    _stopPolling();
    emit(RedemptionFailed('Your voucher is taking longer than expected. Check "My Vouchers" later.'));
  }

  void _onReset(ResetRedemption event, Emitter<RedemptionState> emit) {
    _stopPolling();
    emit(RedemptionInitial());
  }

  void _startPolling(String orderId) {
    _stopPolling();
    
    // Per Hubble docs: wait 1 min before first poll, max 5 attempts, interval 2 mins
    int attempt = 1;
    const maxAttempts = 5;
    
    _pollingTimer = Timer(const Duration(minutes: 1), () async {
      _pollInternal(orderId, attempt, maxAttempts);
    });
  }

  void _pollInternal(String orderId, int attempt, int maxAttempts) async {
    try {
      final result = await _voucherService.pollOrderStatus(orderId);
      add(_UpdateRedemptionResult(result));
      
      if (result.status == VoucherOrderStatus.processing && attempt < maxAttempts) {
        _pollingTimer = Timer(const Duration(minutes: 2), () {
          _pollInternal(orderId, attempt + 1, maxAttempts);
        });
      } else if (result.status == VoucherOrderStatus.processing && attempt >= maxAttempts) {
        add(_RedemptionPollingTimeout());
      }
    } catch (_) {
      // Retry on network error if attempts left
      if (attempt < maxAttempts) {
        _pollingTimer = Timer(const Duration(minutes: 2), () {
          _pollInternal(orderId, attempt + 1, maxAttempts);
        });
      } else {
        add(_RedemptionPollingTimeout());
      }
    }
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
