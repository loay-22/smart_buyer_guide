class ProductAnalysisModel {
  const ProductAnalysisModel({
    required this.productName,
    required this.estimatedPriceNew,
    required this.estimatedPriceUsed,
    required this.currency,
    required this.advantages,
    required this.disadvantages,
    required this.recommendedProducts,
  });

  final String productName;
  final double estimatedPriceNew;
  final double estimatedPriceUsed;
  final String currency;
  final List<String> advantages;
  final List<String> disadvantages;
  final List<RecommendedProductModel> recommendedProducts;

  factory ProductAnalysisModel.fromJson(Map<String, dynamic> json) {
    return ProductAnalysisModel(
      productName: json['productName']?.toString() ?? '',
      estimatedPriceNew: (json['estimatedPriceNew'] as num?)?.toDouble() ?? 0,
      estimatedPriceUsed: (json['estimatedPriceUsed'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'YER',
      advantages: List<String>.from(json['advantages'] ?? []),
      disadvantages: List<String>.from(json['disadvantages'] ?? []),
      recommendedProducts: (json['recommendedProducts'] as List<dynamic>? ?? [])
          .map((item) => RecommendedProductModel.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'estimatedPriceNew': estimatedPriceNew,
      'estimatedPriceUsed': estimatedPriceUsed,
      'currency': currency,
      'advantages': advantages,
      'disadvantages': disadvantages,
      'recommendedProducts': recommendedProducts.map((e) => e.toJson()).toList(),
    };
  }
}

class RecommendedProductModel {
  const RecommendedProductModel({
    required this.name,
    required this.newPrice,
    required this.usedPrice,
    required this.advantages,
    required this.disadvantages,
  });

  final String name;
  final double newPrice;
  final double usedPrice;
  final List<String> advantages;
  final List<String> disadvantages;

  factory RecommendedProductModel.fromJson(Map<String, dynamic> json) {
    return RecommendedProductModel(
      name: json['name']?.toString() ?? '',
      newPrice: (json['newPrice'] as num?)?.toDouble() ?? 0,
      usedPrice: (json['usedPrice'] as num?)?.toDouble() ?? 0,
      advantages: List<String>.from(json['advantages'] ?? []),
      disadvantages: List<String>.from(json['disadvantages'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'newPrice': newPrice,
      'usedPrice': usedPrice,
      'advantages': advantages,
      'disadvantages': disadvantages,
    };
  }
}
