import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/voucher_models.dart';
import '../services/voucher_service.dart';

// Events
abstract class VoucherEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadBrands extends VoucherEvent {
  final String? category;
  final String? search;
  LoadBrands({this.category, this.search});

  @override
  List<Object?> get props => [category, search];
}

class SearchBrands extends VoucherEvent {
  final String query;
  SearchBrands(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterByCategory extends VoucherEvent {
  final String category;
  FilterByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

// States
abstract class VoucherState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VoucherInitial extends VoucherState {}

class VoucherLoading extends VoucherState {}

class VoucherLoaded extends VoucherState {
  final List<GiftCardBrand> brands;
  final String selectedCategory;
  final String searchQuery;

  VoucherLoaded({
    required this.brands,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [brands, selectedCategory, searchQuery];

  VoucherLoaded copyWith({
    List<GiftCardBrand>? brands,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return VoucherLoaded(
      brands: brands ?? this.brands,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class VoucherError extends VoucherState {
  final String message;
  VoucherError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class VoucherBloc extends Bloc<VoucherEvent, VoucherState> {
  final VoucherService _voucherService;

  VoucherBloc({required VoucherService voucherService})
      : _voucherService = voucherService,
        super(VoucherInitial()) {
    on<LoadBrands>(_onLoadBrands);
    on<SearchBrands>(_onSearchBrands);
    on<FilterByCategory>(_onFilterByCategory);
  }

  Future<void> _onLoadBrands(LoadBrands event, Emitter<VoucherState> emit) async {
    final String currentCategory = event.category ?? 
        (state is VoucherLoaded ? (state as VoucherLoaded).selectedCategory : 'All');
    final String currentSearch = event.search ?? 
        (state is VoucherLoaded ? (state as VoucherLoaded).searchQuery : '');

    emit(VoucherLoading());
    try {
      final brands = await _voucherService.getBrands(
        category: currentCategory,
        search: currentSearch,
      );
      emit(VoucherLoaded(
        brands: brands,
        selectedCategory: currentCategory,
        searchQuery: currentSearch,
      ));
    } catch (e) {
      emit(VoucherError('Failed to load gift card brands.'));
    }
  }

  Future<void> _onSearchBrands(SearchBrands event, Emitter<VoucherState> emit) async {
    if (state is VoucherLoaded) {
      final s = state as VoucherLoaded;
      add(LoadBrands(category: s.selectedCategory, search: event.query));
    } else {
      add(LoadBrands(search: event.query));
    }
  }

  Future<void> _onFilterByCategory(FilterByCategory event, Emitter<VoucherState> emit) async {
    if (state is VoucherLoaded) {
      final s = state as VoucherLoaded;
      add(LoadBrands(category: event.category, search: s.searchQuery));
    } else {
      add(LoadBrands(category: event.category));
    }
  }
}
