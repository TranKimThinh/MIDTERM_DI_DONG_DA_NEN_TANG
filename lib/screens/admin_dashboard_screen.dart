import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/admin_provider.dart';
import '../utils/format_helper.dart';
import '../widgets/product_detail_dialog.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/product_image.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runStockAction(
    BuildContext context,
    Future<String?> Function() action, {
    String? successMessage,
  }) async {
    final error = await action();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }
    if (successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _adjustQuantity(
    BuildContext context,
    ProductModel product,
    int delta,
  ) {
    return _runStockAction(
      context,
      () => context.read<AdminProvider>().adjustQuantity(product, delta),
    );
  }

  Future<void> _setStockStatus(
    BuildContext context,
    ProductModel product,
    ProductStockStatus status,
  ) {
    if (product.stockStatus == status) return Future<void>.value();
    return _runStockAction(
      context,
      () => context.read<AdminProvider>().setStockStatus(product, status),
      successMessage:
          'Đã chuyển "${product.name}" sang ${status.label} (soluong = ${status.defaultQuantity})',
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductModel product,
  ) async {
    final provider = context.read<AdminProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" không?\nThao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa sản phẩm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await provider.deleteProduct(product);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã xóa sản phẩm "${product.name}" thành công!'),
        backgroundColor: error != null ? Colors.red : Colors.green.shade700,
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có muốn đăng xuất khỏi phân hệ Admin không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AdminProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final products = provider.filteredProducts;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideScreen = screenWidth >= 860;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quản Lý Sản Phẩm',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (provider.adminEmail != null && isWideScreen) ...[
            Chip(
              avatar: const Icon(Icons.admin_panel_settings, size: 18),
              label: Text(provider.adminEmail!),
            ),
            const SizedBox(width: 10),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, size: 18),
              label: isWideScreen
                  ? const Text('Đăng xuất')
                  : const Text('Thoát'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.all(isWideScreen ? 20 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provider.streamError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lỗi đồng bộ Firestore: ${provider.streamError}',
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. THỐNG KÊ NHANH (TÍNH TỪ 4 TRƯỜNG DỮ LIỆU)
                _StatsSection(
                  totalProducts: provider.totalProductsCount,
                  totalQuantity: provider.totalQuantityCount,
                  totalValue: provider.totalInventoryValue,
                  lowStockCount: provider.lowOrOutOfStockCount,
                  isWide: isWideScreen,
                ),
                const SizedBox(height: 14),

                // 2. THANH CÔNG CỤ TÌM KIẾM, LỌC, SẮP XẾP & NÚT THÊM
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: isWideScreen
                        ? Row(
                            children: [
                              Expanded(child: _buildSearchField(provider)),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 180,
                                child: _buildFilterDropdown(provider),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 205,
                                child: _buildSortDropdown(provider),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: () =>
                                    ProductFormDialog.show(context),
                                icon: const Icon(Icons.add_box_outlined),
                                label: const Text('Thêm sản phẩm'),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSearchField(provider),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFilterDropdown(provider),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildSortDropdown(provider)),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. DANH SÁCH SẢN PHẨM
                Expanded(
                  child: _buildProductsContent(
                    context: context,
                    provider: provider,
                    products: products,
                    isWideScreen: isWideScreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: isWideScreen
          ? null
          : FloatingActionButton.extended(
              onPressed: () => ProductFormDialog.show(context),
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
            ),
    );
  }

  Widget _buildSearchField(AdminProvider provider) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm theo tên sản phẩm...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                tooltip: 'Xóa tìm kiếm',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
              )
            : null,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: provider.setSearchQuery,
    );
  }

  Widget _buildFilterDropdown(AdminProvider provider) {
    return DropdownButtonFormField<ProductStockFilter>(
      initialValue: provider.stockFilter,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: 'Tồn kho',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: ProductStockFilter.all,
          child: Text('Tất cả', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: ProductStockFilter.inStock,
          child: Text('Còn hàng (> 0)', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: ProductStockFilter.lowStock,
          child: Text('Sắp hết (1–5)', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: ProductStockFilter.outOfStock,
          child: Text('Hết hàng (0)', overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: (val) {
        if (val != null) provider.setStockFilter(val);
      },
    );
  }

  Widget _buildSortDropdown(AdminProvider provider) {
    return DropdownButtonFormField<ProductSortOption>(
      initialValue: provider.sortOption,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: 'Sắp xếp',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: ProductSortOption.defaultOrder,
          child: Text('Mặc định', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: ProductSortOption.nameAsc,
          child: Text('Tên A → Z', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: ProductSortOption.nameDesc,
          child: Text('Tên Z → A', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: ProductSortOption.priceAsc,
          child: Text('Giá thấp → cao', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: ProductSortOption.priceDesc,
          child: Text('Giá cao → thấp', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: ProductSortOption.quantityDesc,
          child: Text('Số lượng nhiều nhất', overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: (val) {
        if (val != null) provider.setSortOption(val);
      },
    );
  }

  Widget _buildProductsContent({
    required BuildContext context,
    required AdminProvider provider,
    required List<ProductModel> products,
    required bool isWideScreen,
  }) {
    if (provider.isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      final hasFilter =
          provider.searchQuery.trim().isNotEmpty ||
          provider.stockFilter != ProductStockFilter.all;
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant
                .withValues(alpha: 0.6),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasFilter
                      ? Icons.search_off_rounded
                      : Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  hasFilter
                      ? 'Không tìm thấy sản phẩm phù hợp với bộ lọc.'
                      : 'Chưa có sản phẩm nào trong cơ sở dữ liệu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                if (hasFilter)
                  OutlinedButton(
                    onPressed: () {
                      _searchController.clear();
                      provider.setSearchQuery('');
                      provider.setStockFilter(ProductStockFilter.all);
                    },
                    child: const Text('Đặt lại bộ lọc'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => ProductFormDialog.show(context),
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Thêm sản phẩm đầu tiên'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (isWideScreen) {
      return _buildWebDataTable(context, products);
    }
    return _buildMobileCardList(context, products);
  }

  Widget _buildWebDataTable(BuildContext context, List<ProductModel> products) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  ),
                  dataRowMinHeight: 68,
                  dataRowMaxHeight: 78,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'STT',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Hình ảnh',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tên sản phẩm',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Giá bán',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Số lượng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Trạng thái',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Thao tác',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: List<DataRow>.generate(products.length, (index) {
                    final product = products[index];

                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                ProductDetailDialog.show(context, product),
                            child: ProductImage(
                              imageValue: product.image,
                              size: 50,
                              borderRadius: 10,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          Text(
                            FormatHelper.formatCurrency(product.price),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Giảm số lượng',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 19,
                                ),
                                onPressed: product.soluong > 0
                                    ? () =>
                                          _adjustQuantity(context, product, -1)
                                    : null,
                              ),
                              SizedBox(
                                width: 34,
                                child: Text(
                                  '${product.soluong}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Tăng số lượng',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 19,
                                ),
                                onPressed: () =>
                                    _adjustQuantity(context, product, 1),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          _StockStatusMenuBadge(
                            status: product.stockStatus,
                            onSelected: (status) =>
                                _setStockStatus(context, product, status),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Xem chi tiết',
                                icon: const Icon(
                                  Icons.info_outline,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    ProductDetailDialog.show(context, product),
                              ),
                              IconButton(
                                tooltip: 'Sửa sản phẩm',
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.orange,
                                ),
                                onPressed: () => ProductFormDialog.show(
                                  context,
                                  productToEdit: product,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Xóa sản phẩm',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, product),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileCardList(
    BuildContext context,
    List<ProductModel> products,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 84),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => ProductDetailDialog.show(context, product),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImage(
                    imageValue: product.image,
                    size: 70,
                    borderRadius: 12,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StockStatusMenuBadge(
                              status: product.stockStatus,
                              compact: true,
                              onSelected: (status) =>
                                  _setStockStatus(context, product, status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          FormatHelper.formatCurrency(product.price),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Số lượng: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            InkWell(
                              onTap: product.soluong > 0
                                  ? () => _adjustQuantity(context, product, -1)
                                  : null,
                              child: Icon(
                                Icons.remove_circle_outline,
                                size: 20,
                                color: product.soluong > 0
                                    ? colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                '${product.soluong}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _adjustQuantity(context, product, 1),
                              child: Icon(
                                Icons.add_circle_outline,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  ProductDetailDialog.show(context, product),
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text('Xem'),
                            ),
                            TextButton.icon(
                              onPressed: () => ProductFormDialog.show(
                                context,
                                productToEdit: product,
                              ),
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: Colors.orange,
                              ),
                              label: const Text(
                                'Sửa',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _confirmDelete(context, product),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Xóa',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsSection extends StatelessWidget {
  final int totalProducts;
  final int totalQuantity;
  final double totalValue;
  final int lowStockCount;
  final bool isWide;

  const _StatsSection({
    required this.totalProducts,
    required this.totalQuantity,
    required this.totalValue,
    required this.lowStockCount,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        icon: Icons.inventory_2_outlined,
        label: 'Tổng sản phẩm',
        value: '$totalProducts',
        color: Colors.indigo,
      ),
      _StatCard(
        icon: Icons.layers_outlined,
        label: 'Tổng số lượng',
        value: FormatHelper.formatNumber(totalQuantity),
        color: Colors.teal,
      ),
      _StatCard(
        icon: Icons.monetization_on_outlined,
        label: 'Giá trị tồn kho',
        value: FormatHelper.formatCurrency(totalValue),
        color: Colors.blue.shade700,
      ),
      _StatCard(
        icon: Icons.warning_amber_outlined,
        label: 'Sắp hết / Hết',
        value: '$lowStockCount',
        color: Colors.orange.shade800,
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 8),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 8),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockStatusMenuBadge extends StatelessWidget {
  final ProductStockStatus status;
  final ValueChanged<ProductStockStatus> onSelected;
  final bool compact;

  const _StockStatusMenuBadge({
    required this.status,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ProductStockStatus>(
      tooltip: 'Đổi nhanh trạng thái kho',
      initialValue: status,
      onSelected: onSelected,
      itemBuilder: (context) {
        return ProductStockStatus.values.map((option) {
          final isCurrent = option == status;
          return PopupMenuItem<ProductStockStatus>(
            value: option,
            child: Row(
              children: [
                Icon(option.icon, size: 18, color: option.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? option.color : null,
                    ),
                  ),
                ),
                Text(
                  '= ${option.defaultQuantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check, size: 16, color: option.color),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: status.color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.label,
              style: TextStyle(
                color: status.color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: compact ? 15 : 16,
              color: status.color,
            ),
          ],
        ),
      ),
    );
  }
}
