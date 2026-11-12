import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/image_helper.dart';

/// Hiển thị hình ảnh sản phẩm hỗ trợ Base64 Data URI, Link URL mạng,
/// và ảnh khung mặc định khi chưa có ảnh hoặc ảnh lỗi.
class ProductImage extends StatelessWidget {
  final String imageValue;
  final double size;
  final double borderRadius;

  const ProductImage({
    super.key,
    required this.imageValue,
    this.size = 56,
    this.borderRadius = 12,
  });

  Widget _buildFallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        size: size * 0.48,
        color: colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = imageValue.trim();
    if (trimmed.isEmpty) {
      return _buildFallback(context);
    }

    final Uint8List? memoryBytes = ImageHelper.decodeBase64Image(trimmed);
    if (memoryBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          memoryBytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(context),
        ),
      );
    }

    if (ImageHelper.isNetworkUrl(trimmed)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          trimmed,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (_, _, _) => _buildFallback(context),
        ),
      );
    }

    return _buildFallback(context);
  }
}

