import 'dart:async';
import '../../features/orders/bloc/orders_bloc.dart';

class OrdersRepository {
  // Simulate database/API state for the session
  final List<OrderSummary> _mockOrders = [
    OrderSummary(
      orderId: 'POL-3B668B7A',
      product: 'amit yadssv',
      amount: 'Rs. 899',
      date: 'Jun 12, 2026',
      status: 'Active',
      canClaim: true,
    ),
    OrderSummary(
      orderId: 'POL-30ED2CF5',
      product: 'Digipe solar',
      amount: 'Rs. 5399',
      date: 'Jun 12, 2026',
      status: 'Claim Approved',
      canClaim: false,
    ),
  ];

  final _ordersController = StreamController<List<OrderSummary>>.broadcast();

  Stream<List<OrderSummary>> get ordersStream => _ordersController.stream;

  Future<List<OrderSummary>> fetchOrders() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return List.from(_mockOrders);
  }

  Future<void> placeOrder(OrderSummary newOrder) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockOrders.insert(0, newOrder);
    _ordersController.add(List.from(_mockOrders));
  }
}
