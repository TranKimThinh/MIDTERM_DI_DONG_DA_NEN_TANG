import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../utils/format_helper.dart';
import '../utils/image_helper.dart';
import 'product_form_dialog.dart';
import 'product_image.dart';

class ProductDetailDialog extends StatelessWidget {
  final ProductModel product;

  const ProductDetailDialog({super.key, required this.product});

  static Future<void> show(BuildContext context, ProductModel product) {
    return showDialog<void>(
      context: context,
      builder: (_) => ProductDetailDialog(product: product),
    );
  }

  String _imageTypeLabel(String image) {
    final trimmed = image.trim();
    if (trimmed.isEmpty) return 'Chưa có ảnh (dùng ảnh mặc định)';
    if (ImageHelper.isBase64DataUri(trimmed)) return 'Ảnh tải lên (Base64)';
    if (ImageHelper.isNetworkUrl(trimmed)) return 'Đường dẫn URL';
    return 'Chuỗi dữ liệu ảnh';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stockStatus = product.stockStatus;
    final stockColor = stockStatus.color;
    final totalValue = product.price * product.soluong;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProductImage(
              imageValue: product.image,
              size: 112,
              borderRadius: 18,
            ),
            const SizedBox(height: 14),
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: stockColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                stockStatus.label,
                style: TextStyle(
                  color: stockColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.attach_money,
              label: 'Giá sản phẩm (price)',
              value: FormatHelper.formatCurrency(product.price),
            ),
            _InfoRow(
              icon: Icons.inventory_outlined,
              label: 'Số lượng tồn (soluong)',
              value: '${FormatHelper.formatNumber(product.soluong)} sản phẩm',
            ),
            _InfoRow(
              icon: Icons.calculate_outlined,
              label: 'Tổng giá trị tồn',
              value: FormatHelper.formatCurrency(totalValue),
            ),
            _InfoRow(
              icon: Icons.image_outlined,
              label: 'Hình ảnh (image)',
              value: _imageTypeLabel(product.image),
            ),
            if (product.id != null)
              _InfoRow(
                icon: Icons.key_outlined,
                label: 'Document ID',
                value: product.id!,
                valueColor: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            ProductFormDialog.show(context, productToEdit: product);
          },
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Chỉnh sửa'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: valueColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

