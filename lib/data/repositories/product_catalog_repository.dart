import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';

class ProductCatalogRepository {
  ProductCatalogRepository(this._supabase);

  final SupabaseClient _supabase;

  Stream<List<Product>> streamProducts() {
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(Product.fromJson).toList());
  }

  Future<List<Product>> fetchProducts() async {
    final response = await _supabase.from('products').select().order('name');
    return (response as List).map((row) => Product.fromJson(row as Map<String, dynamic>)).toList();
  }
}
