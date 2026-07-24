import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/api_models.dart';
import '../../../../core/constants/api_constants.dart';

// Events
abstract class ProductEvent {}

class LoadProducts extends ProductEvent {}

class SelectProduct extends ProductEvent {
  final Product product;
  SelectProduct(this.product);
}

class SelectPlan extends ProductEvent {
  final Plan plan;
  SelectPlan(this.plan);
}

// States
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final Product selectedProduct;
  final List<Plan> availablePlans;
  final Plan? selectedPlan;
  final Map<String, List<Plan>> productPlans; // productId -> plans

  ProductLoaded({
    required this.products,
    required this.selectedProduct,
    required this.availablePlans,
    this.selectedPlan,
    this.productPlans = const {},
  });

  ProductLoaded copyWith({
    List<Product>? products,
    Product? selectedProduct,
    List<Plan>? availablePlans,
    Plan? selectedPlan,
    Map<String, List<Plan>>? productPlans,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      availablePlans: availablePlans ?? this.availablePlans,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      productPlans: productPlans ?? this.productPlans,
    );
  }
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}

// BLoC
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ApiService _apiService;

  ProductBloc({required ApiService apiService})
      : _apiService = apiService,
        super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<SelectProduct>(_onSelectProduct);
    on<SelectPlan>(_onSelectPlan);
  }

  String _getErrorMessage(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.badResponse) {
        final response = e.response;
        if (response != null && response.data is String && (response.data as String).contains('<!DOCTYPE html>')) {
          return "The server at ${ApiConstants.baseUrl} returned an HTML page instead of API data. This usually means the API Base URL is incorrect or the endpoint doesn't exist.";
        }
        return "Server Error (${response?.statusCode}): ${response?.statusMessage}";
      }
      if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
        return "Could not connect to the server at ${ApiConstants.baseUrl}. Please check your internet connection.";
      }
    }
    return "Failed to load products: ${e.toString()}";
  }

  Future<void> _onLoadProducts(
      LoadProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final products = await _apiService.getProducts();
      if (products.isEmpty) {
        emit(ProductError("No products available in the database"));
        return;
      }

      Map<String, List<Plan>> productPlansMap = {};

      // Fetch plans for all products to show "Starting at" price on Home
      for (var p in products) {
        try {
          final plans = await _apiService.getPlansForProduct(p.id);
          productPlansMap[p.id] = plans;
        } catch (_) {
          productPlansMap[p.id] = [];
        }
      }

      final firstProduct = products.first;
      final selectedProductPlans = productPlansMap[firstProduct.id] ?? [];

      emit(ProductLoaded(
        products: products,
        selectedProduct: firstProduct,
        availablePlans: selectedProductPlans,
        // FIX: Set to null initially so the UI's listener can calculate and auto-select the minimums
        selectedPlan: null,
        productPlans: productPlansMap,
      ));
    } catch (e) {
      emit(ProductError(_getErrorMessage(e)));
    }
  }

  Future<void> _onSelectProduct(SelectProduct event, Emitter<ProductState> emit) async {
    if (state is ProductLoaded) {
      final s = state as ProductLoaded;

      // If we already have plans cached for this product, use them immediately
      if (s.productPlans.containsKey(event.product.id)) {
        final plans = s.productPlans[event.product.id]!;

        // FIX: Rebuild state directly rather than copyWith to guarantee selectedPlan is cleared to null.
        // This prevents the previous product's plan from bleeding over into this one.
        emit(ProductLoaded(
          products: s.products,
          selectedProduct: event.product,
          availablePlans: plans,
          selectedPlan: null,
          productPlans: s.productPlans,
        ));
        return;
      }

      emit(ProductLoading());
      try {
        final plans = await _apiService.getPlansForProduct(event.product.id);
        Map<String, List<Plan>> updatedMap = Map.from(s.productPlans);
        updatedMap[event.product.id] = plans;

        // FIX: Same as above, emit entirely new ProductLoaded to force selectedPlan to null
        emit(ProductLoaded(
          products: s.products,
          selectedProduct: event.product,
          availablePlans: plans,
          selectedPlan: null,
          productPlans: updatedMap,
        ));
      } catch (e) {
        emit(ProductError("Failed to load plans for product"));
      }
    }
  }

  void _onSelectPlan(SelectPlan event, Emitter<ProductState> emit) {
    if (state is ProductLoaded) {
      final s = state as ProductLoaded;
      // copyWith works perfectly here because we are passing a non-null plan
      emit(s.copyWith(selectedPlan: event.plan));
    }
  }
}