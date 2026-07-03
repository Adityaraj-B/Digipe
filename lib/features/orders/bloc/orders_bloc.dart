import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/local_order_store.dart';
import '../../../core/models/api_models.dart';

abstract class OrdersEvent {}

class FetchOrders extends OrdersEvent {
  final String searchQuery;
  final String statusFilter;
  FetchOrders({this.searchQuery = '', this.statusFilter = 'All Status'});
}

class ClearOrdersEvent extends OrdersEvent {}

class DeleteOrderLocally extends OrdersEvent {
  final String orderId;
  DeleteOrderLocally(this.orderId);
}

abstract class OrdersState {}
class OrdersInitial extends OrdersState {}
class OrdersLoading extends OrdersState {}
class OrdersLoaded extends OrdersState {
  final List<OrderSummary> orders;
  final int totalEntries;
  final int currentPage;
  OrdersLoaded({required this.orders, required this.totalEntries, this.currentPage = 1});
}
class OrdersError extends OrdersState {
  final String message;
  OrdersError(this.message);
}

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final ApiService _apiService;

  OrdersBloc({required ApiService apiService})
      : _apiService = apiService,
        super(OrdersInitial()) {
    on<FetchOrders>(_onFetchOrders);
    on<ClearOrdersEvent>((event, emit) => emit(OrdersInitial()));
    on<DeleteOrderLocally>(_onDeleteOrderLocally);
  }

  Future<void> _onFetchOrders(FetchOrders event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    try {
      final orders = await _apiService.getMyOrders();
      final hiddenIds = await LocalOrderStore.getHiddenIds();

      var filtered = orders.where((o) => !hiddenIds.contains(o.orderId)).toList();

      if (event.searchQuery.isNotEmpty) {
        filtered = filtered
            .where((o) => o.orderId.toLowerCase().contains(event.searchQuery.toLowerCase()))
            .toList();
      }
      if (event.statusFilter != 'All Status') {
        filtered = filtered.where((o) => o.status == event.statusFilter).toList();
      }

      emit(OrdersLoaded(orders: filtered, totalEntries: filtered.length, currentPage: 1));
    } catch (e) {
      emit(OrdersError('Failed to load orders: $e'));
    }
  }

  Future<void> _onDeleteOrderLocally(DeleteOrderLocally event, Emitter<OrdersState> emit) async {
    await LocalOrderStore.hideOrder(event.orderId);
    final current = state;
    if (current is OrdersLoaded) {
      final updated = current.orders.where((o) => o.orderId != event.orderId).toList();
      emit(OrdersLoaded(
        orders: updated,
        totalEntries: updated.length,
        currentPage: current.currentPage,
      ));
    }
  }
}