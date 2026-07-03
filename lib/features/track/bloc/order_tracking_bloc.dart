import 'package:flutter_bloc/flutter_bloc.dart';
import '../service/order_tracking_model.dart';
import '../service/order_tracking_repo.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class OrderTrackingEvent {}

class LoadOrder extends OrderTrackingEvent {
  final String orderId;
  LoadOrder(this.orderId);
}

class LoadLatestOrder extends OrderTrackingEvent {}

class RefreshOrder extends OrderTrackingEvent {
  final String orderId;
  RefreshOrder(this.orderId);
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class OrderTrackingState {}

class OrderTrackingInitial extends OrderTrackingState {}

class OrderTrackingLoading extends OrderTrackingState {}

class OrderTrackingRefreshing extends OrderTrackingState {
  final OrderTracking currentOrder;
  OrderTrackingRefreshing(this.currentOrder);
}

class OrderTrackingLoaded extends OrderTrackingState {
  final OrderTracking order;
  OrderTrackingLoaded(this.order);
}

class OrderTrackingError extends OrderTrackingState {
  final String message;
  OrderTrackingError(this.message);
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class OrderTrackingBloc
    extends Bloc<OrderTrackingEvent, OrderTrackingState> {
  final OrderTrackingRepository _repository;

  OrderTrackingBloc({required OrderTrackingRepository repository})
      : _repository = repository,
        super(OrderTrackingInitial()) {
    on<LoadOrder>(_onLoadOrder);
    on<LoadLatestOrder>(_onLoadLatestOrder);
    on<RefreshOrder>(_onRefreshOrder);
  }

  Future<void> _onLoadOrder(
      LoadOrder event, Emitter<OrderTrackingState> emit) async {
    emit(OrderTrackingLoading());
    try {
      final order = await _repository.fetchOrder(event.orderId);
      emit(OrderTrackingLoaded(order));
    } catch (e) {
      emit(OrderTrackingError(_friendlyMessage(e)));
    }
  }

  Future<void> _onLoadLatestOrder(
      LoadLatestOrder event, Emitter<OrderTrackingState> emit) async {
    emit(OrderTrackingLoading());
    try {
      if (_repository is OrderTrackingApiRepository) {
        final order =
        await (_repository).fetchOrder('latest');
        emit(OrderTrackingLoaded(order));
      } else {
        // Mock repository fallback
        final order = await _repository.fetchOrder('latest');
        emit(OrderTrackingLoaded(order));
      }
    } catch (e) {
      emit(OrderTrackingError(_friendlyMessage(e)));
    }
  }

  Future<void> _onRefreshOrder(
      RefreshOrder event, Emitter<OrderTrackingState> emit) async {
    if (state is OrderTrackingLoaded) {
      emit(OrderTrackingRefreshing((state as OrderTrackingLoaded).order));
    }
    try {
      final order = await _repository.fetchOrder(event.orderId);
      emit(OrderTrackingLoaded(order));
    } catch (e) {
      if (state is OrderTrackingRefreshing) {
        emit(OrderTrackingLoaded(
            (state as OrderTrackingRefreshing).currentOrder));
      }
      emit(OrderTrackingError(_friendlyMessage(e)));
    }
  }

  String _friendlyMessage(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 404) return 'No applications found.';
      if (e.statusCode == 401) return 'Session expired. Please log in again.';
      return 'Server error (${e.statusCode}). Please try again.';
    }
    return 'Something went wrong. Please check your connection.';
  }
}