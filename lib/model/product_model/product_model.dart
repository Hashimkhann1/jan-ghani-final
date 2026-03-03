



import 'package:jan_ghani_final/utils/constant/enum_constant/enum_constant.dart';

class ProductModel {
  final String name;
  final String? image;
  final String sku;
  final String category;
  final int stock;
  final int minStock;
  final double value;
  final StockStatus status;
  final int variants;
  final String initials;

  const ProductModel({
    required this.name,
    this.image,
    required this.sku,
    required this.category,
    required this.stock,
    required this.minStock,
    required this.value,
    required this.status,
    this.variants = 0,
    required this.initials,
  });
}