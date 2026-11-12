import 'dart:async';

import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_repository.dart';

enum ProductSortOption {
  defaultOrder,
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  quantityDesc,
}

enum ProductStockFilter { all, inStock, lowStock, outOfStock }

class AdminProvider extends ChangeNotifier {
  static const String defaultAdminEmail = 'abc@gmail.com';
  static const String defaultAdminPassword = '123456';

  final ProductRepository _repository;

  StreamSubscription<List<ProductModel>>? _productsSubscription;

  String? _adminEmail;
  List<ProductModel> _products = [];
  bool _isLoadingProducts = true;
  bool _isSubmitting = false;
  String? _streamError;

  String _searchQuery = '';
  ProductSortOption _sortOption = ProductSortOption.defaultOrder;
  ProductStockFilter _stockFilter = ProductStockFilter.all;

  AdminProvider(this._repository) {
    _listenToProducts();
  }

  bool get isUsingFirebase => _repository.isUsingFirebase;
  String? get adminEmail => _adminEmail;
  bool get isAuthenticated => _adminEmail != null;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isSubmitting => _isSubmitting;
  String? get streamError => _streamError;

  String get searchQuery => _searchQuery;
  ProductSortOption get sortOption => _sortOption;
  ProductStockFilter get stockFilter => _stockFilter;

  int get totalProductsCount => _products.length;
  int get totalQuantityCount =>
      _products.fold<int>(0, (sum, p) => sum + p.soluong);
  double get totalInventoryValue =>
      _products.fold<double>(0.0, (sum, p) => sum + (p.price * p.soluong));
  int get lowOrOutOfStockCount => _products
      .where((p) => p.stockStatus != ProductStockStatus.inStock)
      .length;

  List<ProductModel> get filteredProducts {
    Iterable<ProductModel> result = _products;

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((p) => p.name.toLowerCase().contains(query));
    }

    switch (_stockFilter) {
      case ProductStockFilter.all:
        break;
      case ProductStockFilter.inStock:
        result = result.where((p) => p.soluong > 0);
        break;
      case ProductStockFilter.lowStock:
        result = result.where((p) => p.soluong > 0 && p.soluong <= 5);
        break;
      case ProductStockFilter.outOfStock:
        result = result.where((p) => p.soluong <= 0);
        break;
    }

    final list = result.toList();
    switch (_sortOption) {
      case ProductSortOption.defaultOrder:
        break;
      case ProductSortOption.nameAsc:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case ProductSortOption.nameDesc:
        list.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case ProductSortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.quantityDesc:
        list.sort((a, b) => b.soluong.compareTo(a.soluong));
        break;
    }

    return list;
  }

  void _listenToProducts() {
    _isLoadingProducts = true;
    _streamError = null;
    _productsSubscription?.cancel();
    _productsSubscription = _repository.watchProducts().listen(
      (products) {
        _products = products;
        _isLoadingProducts = false;
        _streamError = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoadingProducts = false;
        _streamError = error.toString();
        notifyListeners();
      },
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(ProductSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void setStockFilter(ProductStockFilter filter) {
    _stockFilter = filter;
    notifyListeners();
  }

  /// Đăng nhập phân hệ Admin (xác thực cục bộ để không thêm bảng/trường vào Firestore).
  Future<String?> login(String email, String password) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail == defaultAdminEmail &&
          password == defaultAdminPassword) {
        _adminEmail = normalizedEmail;
        return null;
      }
      return 'Email hoặc mật khẩu Admin không chính xác!';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void logout() {
    _adminEmail = null;
    _searchQuery = '';
    _sortOption = ProductSortOption.defaultOrder;
    _stockFilter = ProductStockFilter.all;
    notifyListeners();
  }

  Future<String?> addProduct(ProductModel product) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final exists = await _repository.isProductNameExists(product.name);
      if (exists) {
        return 'Sản phẩm "${product.name}" đã tồn tại!';
      }
      await _repository.createProduct(product);
      return null;
    } catch (e) {
      return 'Thêm sản phẩm thất bại: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> updateProduct(ProductModel product) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final exists = await _repository.isProductNameExists(
        product.name,
        excludeId: product.id,
      );
      if (exists) {
        return 'Tên sản phẩm "${product.name}" đã được sử dụng!';
      }
      await _repository.updateProduct(product);
      return null;
    } catch (e) {
      return 'Cập nhật thất bại: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Tăng/giảm nhanh số lượng sản phẩm trên danh sách
  Future<String?> adjustQuantity(ProductModel product, int delta) async {
    final nextQty = product.soluong + delta;
    if (nextQty < 0) {
      return 'Số lượng không thể nhỏ hơn 0.';
    }
    try {
      await _repository.updateProduct(product.copyWith(soluong: nextQty));
      return null;
    } catch (e) {
      return 'Không thể cập nhật số lượng: $e';
    }
  }

  Future<String?> setStockStatus(
    ProductModel product,
    ProductStockStatus status,
  ) async {
    if (product.stockStatus == status) {
      return null;
    }
    try {
      await _repository.updateProduct(
        product.copyWith(soluong: status.defaultQuantity),
      );
      return null;
    } catch (e) {
      return 'Không thể cập nhật trạng thái kho: $e';
    }
  }

  Future<String?> deleteProduct(ProductModel product) async {
    if (product.id == null || product.id!.isEmpty) {
      return 'Không tìm thấy ID sản phẩm cần xóa.';
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await _repository.deleteProduct(product.id!);
      return null;
    } catch (e) {
      return 'Xóa thất bại: $e';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }
}
