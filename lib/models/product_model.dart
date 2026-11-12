import 'package:flutter/material.dart';

enum ProductStockStatus {
  inStock,
  lowStock,
  outOfStock;

  String get label => switch (this) {
    ProductStockStatus.inStock => 'Còn hàng',
    ProductStockStatus.lowStock => 'Sắp hết',
    ProductStockStatus.outOfStock => 'Hết hàng',
  };
  int get defaultQuantity => switch (this) {
    ProductStockStatus.inStock => 10,
    ProductStockStatus.lowStock => 3,
    ProductStockStatus.outOfStock => 0,
  };

  Color get color => switch (this) {
    ProductStockStatus.inStock => Colors.green.shade700,
    ProductStockStatus.lowStock => Colors.orange.shade800,
    ProductStockStatus.outOfStock => Colors.red,
  };

  IconData get icon => switch (this) {
    ProductStockStatus.inStock => Icons.check_circle_outline,
    ProductStockStatus.lowStock => Icons.warning_amber_rounded,
    ProductStockStatus.outOfStock => Icons.cancel_outlined,
  };

  static ProductStockStatus fromQuantity(int qty) {
    if (qty <= 0) return ProductStockStatus.outOfStock;
    if (qty <= 5) return ProductStockStatus.lowStock;
    return ProductStockStatus.inStock;
  }
}

class ProductModel {
  final String? id;
  final String name;
  final double price;
  final int soluong;
  final String image;

  const ProductModel({
    this.id,
    required this.name,
    required this.price,
    required this.soluong,
    required this.image,
  });

  ProductStockStatus get stockStatus =>
      ProductStockStatus.fromQuantity(soluong);

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'name': name,
      'price': price,
      'soluong': soluong,
      'image': image,
    };
  }

  factory ProductModel.fromFirestore(String docId, Map<String, dynamic> data) {
    final rawPrice = data['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse('${rawPrice ?? ''}') ?? 0.0;

    final rawQty = data['soluong'];
    final parsedQty = rawQty is num
        ? rawQty.toInt()
        : int.tryParse('${rawQty ?? ''}') ?? 0;

    return ProductModel(
      id: docId,
      name: (data['name'] ?? '').toString(),
      price: parsedPrice,
      soluong: parsedQty,
      image: (data['image'] ?? '').toString(),
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    int? soluong,
    String? image,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      soluong: soluong ?? this.soluong,
      image: image ?? this.image,
    );
  }
}
