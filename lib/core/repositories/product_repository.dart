import 'dart:async';

class ProductVariant {
  final String id;
  final String name;
  final double price;
  final String? imageUrl; // Added imageUrl

  ProductVariant({required this.id, required this.name, required this.price, this.imageUrl});
}

class ProductRepository {
  // Simulate API Base URL
  static const String baseUrl = "https://api.digipe.com/v1";

  Future<List<ProductVariant>> fetchVariants() async {
    // Simulate API Call
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ProductVariant(id: 'v1', name: '₹500 Cover', price: 500),
      ProductVariant(
        id: 'v2', 
        name: '₹1000 Cover', 
        price: 1000,
        // imageUrl: 'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?q=80&w=2072&auto=format&fit=crop', // Uncomment to test
      ),
      ProductVariant(id: 'v3', name: '₹2000 Cover', price: 2000),
      ProductVariant(id: 'v4', name: '₹3000 Cover', price: 3000),
      ProductVariant(id: 'v5', name: '₹4000 Cover', price: 4000),
    ];
  }

  Future<List<String>> fetchDurations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ['1y', '2y', '3y', '4y', '5y'];
  }

  double calculateFinalPrice(double basePrice, String duration) {
    int years = int.parse(duration.replaceAll('y', ''));
    // Simple logic: basePrice * years (could be more complex with discounts)
    return basePrice * years;
  }
}
