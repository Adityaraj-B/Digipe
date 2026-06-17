import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/repositories/product_repository.dart';

// Events
abstract class ProductEvent {}

class LoadProductDetails extends ProductEvent {}

class SelectVariant extends ProductEvent {
  final ProductVariant variant;
  SelectVariant(this.variant);
}

class SelectDuration extends ProductEvent {
  final String duration;
  SelectDuration(this.duration);
}

// States
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ProductVariant> variants;
  final List<String> durations;
  final ProductVariant selectedVariant;
  final String selectedDuration;
  final double totalPrice;

  ProductLoaded({
    required this.variants,
    required this.durations,
    required this.selectedVariant,
    required this.selectedDuration,
    required this.totalPrice,
  });

  ProductLoaded copyWith({
    ProductVariant? selectedVariant,
    String? selectedDuration,
    double? totalPrice,
  }) {
    return ProductLoaded(
      variants: variants,
      durations: durations,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}

// BLoC
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;

  ProductBloc({required ProductRepository repository})
      : _repository = repository,
        super(ProductInitial()) {
    on<LoadProductDetails>(_onLoadProductDetails);
    on<SelectVariant>(_onSelectVariant);
    on<SelectDuration>(_onSelectDuration);
  }

  Future<void> _onLoadProductDetails(
      LoadProductDetails event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final variants = await _repository.fetchVariants();
      final durations = await _repository.fetchDurations();
      
      final defaultVariant = variants[1]; // ₹1000 Cover
      final defaultDuration = durations[0]; // 1y
      final initialPrice = _repository.calculateFinalPrice(defaultVariant.price, defaultDuration);

      emit(ProductLoaded(
        variants: variants,
        durations: durations,
        selectedVariant: defaultVariant,
        selectedDuration: defaultDuration,
        totalPrice: initialPrice,
      ));
    } catch (e) {
      emit(ProductError("Failed to load product info"));
    }
  }

  void _onSelectVariant(SelectVariant event, Emitter<ProductState> emit) {
    if (state is ProductLoaded) {
      final s = state as ProductLoaded;
      final newPrice = _repository.calculateFinalPrice(event.variant.price, s.selectedDuration);
      emit(s.copyWith(selectedVariant: event.variant, totalPrice: newPrice));
    }
  }

  void _onSelectDuration(SelectDuration event, Emitter<ProductState> emit) {
    if (state is ProductLoaded) {
      final s = state as ProductLoaded;
      final newPrice = _repository.calculateFinalPrice(s.selectedVariant.price, event.duration);
      emit(s.copyWith(selectedDuration: event.duration, totalPrice: newPrice));
    }
  }
}
