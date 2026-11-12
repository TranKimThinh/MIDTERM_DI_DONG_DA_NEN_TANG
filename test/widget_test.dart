import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:midterm_crud/main.dart';
import 'package:midterm_crud/models/product_model.dart';
import 'package:midterm_crud/providers/admin_provider.dart';
import 'package:midterm_crud/services/product_repository.dart';

void main() {
  test('ProductModel.toFirestore only contains the 4 allowed fields', () {
    const product = ProductModel(
      id: 'doc-123',
      name: 'Chuột Logitech MX Master 3S',
      price: 2490000,
      soluong: 15,
      image: 'https://example.com/mouse.png',
    );

    final map = product.toFirestore();
    expect(
      map.keys.toSet(),
      equals(<String>{'name', 'price', 'soluong', 'image'}),
    );
    expect(map.containsKey('id'), isFalse);
  });

  test('AdminProvider supports login, add, duplicate check, update, qty adjust, search, delete', () async {
    final provider = AdminProvider(LocalDemoProductRepository());
    await Future<void>.delayed(Duration.zero);

    expect(provider.totalProductsCount, 3);

    final loginFail = await provider.login('admin@gmail.com', 'wrong');
    expect(loginFail, isNotNull);
    expect(provider.isAuthenticated, isFalse);

    final loginOk = await provider.login(
      AdminProvider.defaultAdminEmail,
      AdminProvider.defaultAdminPassword,
    );
    expect(loginOk, isNull);
    expect(provider.isAuthenticated, isTrue);

    // Không cho phép thêm trùng tên sản phẩm
    final duplicateErr = await provider.addProduct(
      const ProductModel(
        name: 'laptop dell xps 13',
        price: 20000000,
        soluong: 5,
        image: '',
      ),
    );
    expect(duplicateErr, isNotNull);

    // Thêm sản phẩm mới hợp lệ
    final addErr = await provider.addProduct(
      const ProductModel(
        name: 'Màn hình LG UltraGear',
        price: 8500000,
        soluong: 7,
        image: 'https://example.com/lg.png',
      ),
    );
    expect(addErr, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(provider.totalProductsCount, 4);

    // Tìm kiếm theo tên
    provider.setSearchQuery('lg ultragear');
    expect(provider.filteredProducts.length, 1);
    final addedProduct = provider.filteredProducts.first;

    // Tăng số lượng nhanh
    final adjustErr = await provider.adjustQuantity(addedProduct, 3);
    expect(adjustErr, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(provider.filteredProducts.first.soluong, 10);

    // Sửa thông tin sản phẩm
    final updateErr = await provider.updateProduct(
      provider.filteredProducts.first.copyWith(name: 'Màn hình LG 27 inch'),
    );
    expect(updateErr, isNull);
    await Future<void>.delayed(Duration.zero);
    provider.setSearchQuery('lg 27 inch');
    expect(provider.filteredProducts.first.name, 'Màn hình LG 27 inch');

    // Đặt nhanh trạng thái kho (Hết hàng -> Sắp hết -> Còn hàng)
    expect(
      await provider.setStockStatus(
        provider.filteredProducts.first,
        ProductStockStatus.outOfStock,
      ),
      isNull,
    );
    await Future<void>.delayed(Duration.zero);
    expect(provider.filteredProducts.first.soluong, 0);
    expect(
      provider.filteredProducts.first.stockStatus,
      ProductStockStatus.outOfStock,
    );

    expect(
      await provider.setStockStatus(
        provider.filteredProducts.first,
        ProductStockStatus.lowStock,
      ),
      isNull,
    );
    await Future<void>.delayed(Duration.zero);
    expect(provider.filteredProducts.first.soluong, 3);
    expect(
      provider.filteredProducts.first.stockStatus,
      ProductStockStatus.lowStock,
    );

    expect(
      await provider.setStockStatus(
        provider.filteredProducts.first,
        ProductStockStatus.inStock,
      ),
      isNull,
    );
    await Future<void>.delayed(Duration.zero);
    expect(provider.filteredProducts.first.soluong, 10);
    expect(
      provider.filteredProducts.first.stockStatus,
      ProductStockStatus.inStock,
    );

    // Xóa sản phẩm vừa thêm
    provider.setSearchQuery('');
    final deleteErr = await provider.deleteProduct(addedProduct);
    expect(deleteErr, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(provider.totalProductsCount, 3);

    provider.dispose();
  });

  testWidgets('Admin login and mobile product list smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AdminProvider(LocalDemoProductRepository()),
        child: const AdminProductApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đăng Nhập Phân Hệ Admin'), findsOneWidget);

    await tester.tap(find.text('Điền nhanh'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Quản Lý Sản Phẩm'), findsOneWidget);
    expect(find.text('Laptop Dell XPS 13'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Bàn phím cơ Keychron K2'),
      200,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Bàn phím cơ Keychron K2'), findsOneWidget);
  });

  testWidgets('Admin dashboard Web layout renders DataTable and Add dialog cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AdminProvider(LocalDemoProductRepository()),
        child: const AdminProductApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Điền nhanh'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Laptop Dell XPS 13'), findsOneWidget);
    expect(find.text('Tai nghe Sony WH-1000XM5'), findsOneWidget);
    expect(find.text('Bàn phím cơ Keychron K2'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Thêm sản phẩm'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm Sản Phẩm Mới'), findsOneWidget);

    // Chọn nhanh trạng thái kho bằng ChoiceChip trong Form sẽ cập nhật `soluong`
    await tester.ensureVisible(find.text('Sắp hết (3)'));
    await tester.tap(find.text('Sắp hết (3)'));
    await tester.pump();
    final qtyField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Số lượng (soluong) *'),
    );
    expect(qtyField.controller?.text, '3');

    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    // Đổi nhanh trạng thái kho trực tiếp trên bảng DataTable (Còn hàng -> Hết hàng)
    expect(
      find.descendant(
        of: find.byType(DataTable),
        matching: find.text('Còn hàng'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(DataTable),
        matching: find.text('Hết hàng'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(DataTable),
        matching: find.text('Còn hàng'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hết hàng').last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(DataTable),
        matching: find.text('Còn hàng'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(DataTable),
        matching: find.text('Hết hàng'),
      ),
      findsNWidgets(2),
    );
  });
}
