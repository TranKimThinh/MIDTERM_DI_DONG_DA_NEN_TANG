import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

abstract class ProductRepository {
  bool get isUsingFirebase;

  Stream<List<ProductModel>> watchProducts();

  Future<bool> isProductNameExists(String name, {String? excludeId});

  Future<void> createProduct(ProductModel product);

  Future<void> updateProduct(ProductModel product);

  Future<void> deleteProduct(String id);
}

class FirestoreProductRepository implements ProductRepository {
  static const String collectionName = 'products';

  final FirebaseFirestore _firestore;

  FirestoreProductRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection(collectionName);

  @override
  bool get isUsingFirebase => true;

  @override
  Stream<List<ProductModel>> watchProducts() {
    return _productsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  @override
  Future<bool> isProductNameExists(String name, {String? excludeId}) async {
    final normalizedName = name.trim().toLowerCase();
    final snapshot = await _productsRef.get();
    for (final doc in snapshot.docs) {
      if (excludeId != null && doc.id == excludeId) continue;
      final existingName = (doc.data()['name'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (existingName == normalizedName) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> createProduct(ProductModel product) async {
    await _productsRef.add(product.toFirestore());
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final docId = product.id;
    if (docId == null || docId.isEmpty) {
      throw ArgumentError('Thiếu document ID để cập nhật sản phẩm.');
    }
    await _productsRef.doc(docId).update(product.toFirestore());
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }
}

class LocalDemoProductRepository implements ProductRepository {
  final List<ProductModel> _store = [
    const ProductModel(
      id: 'demo-1',
      name: 'Laptop Dell XPS 13',
      price: 28500000,
      soluong: 12,
      image: '',
    ),
    const ProductModel(
      id: 'demo-2',
      name: 'Tai nghe Sony WH-1000XM5',
      price: 7990000,
      soluong: 4,
      image: '',
    ),
    const ProductModel(
      id: 'demo-3',
      name: 'Bàn phím cơ Keychron K2',
      price: 2150000,
      soluong: 0,
      image: '',
    ),
  ];

  final StreamController<List<ProductModel>> _controller =
      StreamController<List<ProductModel>>.broadcast();
  int _nextId = 4;

  @override
  bool get isUsingFirebase => false;

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<ProductModel>.unmodifiable(_store));
    }
  }

  @override
  Stream<List<ProductModel>> watchProducts() async* {
    yield List<ProductModel>.unmodifiable(_store);
    yield* _controller.stream;
  }

  @override
  Future<bool> isProductNameExists(String name, {String? excludeId}) async {
    final normalized = name.trim().toLowerCase();
    return _store.any(
      (p) => p.id != excludeId && p.name.trim().toLowerCase() == normalized,
    );
  }

  @override
  Future<void> createProduct(ProductModel product) async {
    _store.insert(0, product.copyWith(id: 'demo-${_nextId++}'));
    _emit();
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final idx = _store.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _store[idx] = product;
      _emit();
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    _store.removeWhere((p) => p.id == id);
    _emit();
  }
}
