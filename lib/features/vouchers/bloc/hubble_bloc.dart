import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/hubble_sdk_service.dart';

// ─────────────────────────────────────────
// Events
// ─────────────────────────────────────────

abstract class HubbleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Trigger this to fetch the SDK token + URL from the backend.
class LoadHubbleSDK extends HubbleEvent {}

/// Trigger this to load the user's transaction history.
class LoadHubbleHistory extends HubbleEvent {}

// ─────────────────────────────────────────
// States
// ─────────────────────────────────────────

abstract class HubbleState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HubbleInitial extends HubbleState {}

class HubbleLoading extends HubbleState {}

/// SDK URL is ready — launch the WebView with [sdkUrl].
class HubbleReady extends HubbleState {
  final String sdkUrl;
  HubbleReady(this.sdkUrl);

  @override
  List<Object?> get props => [sdkUrl];
}

class HubbleError extends HubbleState {
  final String message;
  HubbleError(this.message);

  @override
  List<Object?> get props => [message];
}

class HubbleHistoryLoading extends HubbleState {}

class HubbleHistoryLoaded extends HubbleState {
  final List<HubbleTransaction> transactions;
  HubbleHistoryLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class HubbleHistoryError extends HubbleState {
  final String message;
  HubbleHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────────
// BLoC
// ─────────────────────────────────────────

class HubbleBloc extends Bloc<HubbleEvent, HubbleState> {
  final HubbleSdkService _service;

  HubbleBloc({required HubbleSdkService service})
      : _service = service,
        super(HubbleInitial()) {
    on<LoadHubbleSDK>(_onLoadSDK);
    on<LoadHubbleHistory>(_onLoadHistory);
  }

  Future<void> _onLoadSDK(LoadHubbleSDK event, Emitter<HubbleState> emit) async {
    emit(HubbleLoading());
    try {
      final config = await _service.fetchSdkConfig();
      emit(HubbleReady(config.sdkUrl));
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('401') || msg.contains('Unauthorized')) {
        emit(HubbleError('Please log in to access the Gift Card Store.'));
      } else {
        emit(HubbleError('Could not load Gift Card Store. Please try again.'));
      }
    }
  }

  Future<void> _onLoadHistory(LoadHubbleHistory event, Emitter<HubbleState> emit) async {
    emit(HubbleHistoryLoading());
    try {
      final txns = await _service.fetchTransactions();
      emit(HubbleHistoryLoaded(txns));
    } on Exception {
      emit(HubbleHistoryError('Could not load transaction history.'));
    }
  }
}
