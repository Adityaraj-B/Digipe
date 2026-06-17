import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/orders_repository.dart';

class OrderSummary {
  final String orderId;
  final String product;
  final String amount;
  final String date;
  final String status;
  final bool canClaim;

  OrderSummary({
    required this.orderId,
    required this.product,
    required this.amount,
    required this.date,
    required this.status,
    required this.canClaim,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      orderId: json['order_id'] ?? '',
      product: json['product'] ?? '',
      amount: json['amount'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      canClaim: json['can_claim'] ?? false,
    );
  }
}

abstract class OrdersEvent {}

class FetchOrders extends OrdersEvent {
  final String searchQuery;
  final String statusFilter;

  FetchOrders({this.searchQuery = '', this.statusFilter = 'All Status'});
}

abstract class OrdersState {}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<OrderSummary> orders;
  final int totalEntries;
  final int currentPage;

  OrdersLoaded({
    required this.orders,
    required this.totalEntries,
    required this.currentPage,
  });
}

class OrdersError extends OrdersState {
  final String message;
  OrdersError(this.message);
}

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepository _repository;
  StreamSubscription? _ordersSubscription;

  OrdersBloc({required OrdersRepository repository})
      : _repository = repository,
        super(OrdersInitial()) {
    on<FetchOrders>(_onFetchOrders);
    on<AddOrder>(_onAddOrder);

    // Listen for real-time updates from repository
    _ordersSubscription = _repository.ordersStream.listen((orders) {
      add(FetchOrders()); // Refresh when repository changes
    });
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFetchOrders(
      FetchOrders event,
      Emitter<OrdersState> emit,
      ) async {
    emit(OrdersLoading());
    try {
      final orders = await _repository.fetchOrders();
      
      var filteredOrders = orders;

      if (event.searchQuery.isNotEmpty) {
        filteredOrders = filteredOrders
            .where((order) =>
            order.orderId.toLowerCase().contains(event.searchQuery.toLowerCase()))
            .toList();
      }

      if (event.statusFilter != 'All Status') {
        filteredOrders = filteredOrders
            .where((order) => order.status == event.statusFilter)
            .toList();
      }

      emit(OrdersLoaded(
        orders: filteredOrders,
        totalEntries: orders.length,
        currentPage: 1,
      ));
    } catch (e) {
      emit(OrdersError('Failed to load orders. Please try again.'));
    }
  }

  Future<void> _onAddOrder(AddOrder event, Emitter<OrdersState> emit) async {
    await _repository.placeOrder(event.order);
    // FetchOrders will be triggered by the subscription
  }
}

class AddOrder extends OrdersEvent {
  final OrderSummary order;
  AddOrder(this.order);
}
