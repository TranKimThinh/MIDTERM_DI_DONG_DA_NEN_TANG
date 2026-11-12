import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/admin_provider.dart';
import '../utils/image_helper.dart';
import 'product_image.dart';

/// Form dùng chung cho Thêm mới và Cập nhật sản phẩm (`name`, `price`, `soluong`, `image`).
/// Tự thích ứng: hiển thị dạng Dialog trên Web/Tablet và toàn màn hình trên Mobile.
class ProductFormDialog extends StatefulWidget {
  final ProductModel? productToEdit;

  const ProductFormDialog({
    super.key,
    this.productToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    ProductModel? productToEdit,
  }) async {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => ProductFormDialog(productToEdit: productToEdit),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 740),
            child: ProductFormDialog(productToEdit: productToEdit),
          ),
        ),
      );
    }
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _soluongController;
  late final TextEditingController _imageUrlController;

  String _pickedBase64Image = '';
  bool _isPickingImage = false;
  String? _formError;

  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final product = widget.productToEdit;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(
      text: product != null
          ? (product.price == product.price.roundToDouble()
              ? product.price.toInt().toString()
              : product.price.toString())
          : '',
    );
    _soluongController = TextEditingController(
      text: product != null ? product.soluong.toString() : '',
    );

    final existingImage = product?.image.trim() ?? '';
    if (ImageHelper.isNetworkUrl(existingImage)) {
      _imageUrlController = TextEditingController(text: existingImage);
    } else {
      _imageUrlController = TextEditingController();
      _pickedBase64Image = existingImage;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _soluongController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  String get _effectiveImage {
    if (_pickedBase64Image.isNotEmpty) {
      return _pickedBase64Image;
    }
    return _imageUrlController.text.trim();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isPickingImage = true;
      _formError = null;
    });

    final result = await ImageHelper.pickImageAsBase64(source);
    if (!mounted) return;

    setState(() {
      _isPickingImage = false;
      if (result.error != null) {
        _formError = result.error;
      } else if (!result.cancelled && result.dataUri != null) {
        _pickedBase64Image = result.dataUri!;
        _imageUrlController.clear();
      }
    });
  }

  void _clearImage() {
    setState(() {
      _pickedBase64Image = '';
      _imageUrlController.clear();
      _formError = null;
    });
  }

  void _applyQuickStockStatus(ProductStockStatus status) {
    final nextText = status.defaultQuantity.toString();
    _soluongController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
  }

  Widget _buildQuickStockSelector() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _soluongController,
      builder: (context, value, _) {
        final parsedQty = int.tryParse(value.text.trim());
        final currentStatus = parsedQty != null
            ? ProductStockStatus.fromQuantity(parsedQty)
            : null;
        final colorScheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đặt nhanh trạng thái kho (cập nhật trường soluong):',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProductStockStatus.values.map((status) {
                final isSelected = currentStatus == status;
                return ChoiceChip(
                  avatar: Icon(
                    status.icon,
                    size: 16,
                    color: isSelected ? status.color : colorScheme.onSurfaceVariant,
                  ),
                  label: Text('${status.label} (${status.defaultQuantity})'),
                  selected: isSelected,
                  selectedColor: status.color.withValues(alpha: 0.16),
                  side: BorderSide(
                    color: isSelected
                        ? status.color
                        : colorScheme.outlineVariant.withValues(alpha: 0.8),
                  ),
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? status.color : colorScheme.onSurface,
                  ),
                  onSelected: (_) => _applyQuickStockStatus(status),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _formError = null);

    final parsedPrice = double.parse(_priceController.text.trim());
    final parsedQty = int.parse(_soluongController.text.trim());

    final product = ProductModel(
      id: widget.productToEdit?.id,
      name: _nameController.text.trim(),
      price: parsedPrice,
      soluong: parsedQty,
      image: _effectiveImage,
    );

    final provider = context.read<AdminProvider>();
    final String? error = _isEditing
        ? await provider.updateProduct(product)
        : await provider.addProduct(product);

    if (!mounted) return;

    if (error != null) {
      setState(() => _formError = error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Cập nhật sản phẩm thành công!'
              : 'Thêm sản phẩm thành công!',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<AdminProvider>().isSubmitting;
    final colorScheme = Theme.of(context).colorScheme;
    final title = _isEditing ? 'Cập Nhật Sản Phẩm' : 'Thêm Sản Phẩm Mới';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Đóng',
            onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Khu vực chọn & xem trước hình ảnh (`image`)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  children: [
                    ProductImage(
                      imageValue: _effectiveImage,
                      size: 96,
                      borderRadius: 16,
                    ),
                    const SizedBox(height: 12),
                    if (_pickedBase64Image.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Chip(
                          avatar: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Đã chọn ảnh từ thiết bị'),
                          onDeleted: _clearImage,
                          deleteButtonTooltipMessage: 'Xóa ảnh đã chọn',
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isPickingImage
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: Text(
                            kIsWeb ? 'Chọn ảnh từ máy' : 'Chọn từ thư viện',
                          ),
                        ),
                        if (!kIsWeb)
                          OutlinedButton.icon(
                            onPressed: _isPickingImage
                                ? null
                                : () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Chụp ảnh'),
                          ),
                        if (_effectiveImage.isNotEmpty)
                          TextButton.icon(
                            onPressed: _clearImage,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Bỏ ảnh'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _imageUrlController,
                      onChanged: (_) {
                        setState(() {
                          if (_imageUrlController.text.trim().isNotEmpty) {
                            _pickedBase64Image = '';
                          }
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Hoặc dán Link URL hình ảnh (image)',
                        hintText: 'https://example.com/product.jpg',
                        prefixIcon: const Icon(Icons.link),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        final trimmed = val?.trim() ?? '';
                        if (trimmed.isEmpty) return null;
                        if (!ImageHelper.isNetworkUrl(trimmed)) {
                          return 'URL phải bắt đầu bằng http:// hoặc https://';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tên sản phẩm (`name`)
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Tên sản phẩm (name) *',
                  hintText: 'Ví dụ: Laptop Dell XPS 13',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  final trimmed = val?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Vui lòng nhập tên sản phẩm';
                  if (trimmed.length < 2) {
                    return 'Tên sản phẩm phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Giá sản phẩm (`price`)
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Giá sản phẩm (price) *',
                  hintText: 'Ví dụ: 15000000',
                  suffixText: 'VNĐ',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  final trimmed = val?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Vui lòng nhập giá sản phẩm';
                  final parsed = double.tryParse(trimmed);
                  if (parsed == null) return 'Giá sản phẩm phải là số hợp lệ';
                  if (parsed < 0) return 'Giá sản phẩm không được âm';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Số lượng (`soluong`)
              TextFormField(
                controller: _soluongController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSubmit(),
                decoration: InputDecoration(
                  labelText: 'Số lượng (soluong) *',
                  hintText: 'Ví dụ: 10',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  final trimmed = val?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Vui lòng nhập số lượng';
                  final parsed = int.tryParse(trimmed);
                  if (parsed == null) return 'Số lượng phải là số nguyên';
                  if (parsed < 0) return 'Số lượng không được âm';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildQuickStockSelector(),

              if (_formError != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
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
                          _formError!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: (isSubmitting || _isPickingImage)
                    ? null
                    : _handleSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  isSubmitting
                      ? 'Đang lưu...'
                      : (_isEditing ? 'Lưu thay đổi' : 'Thêm sản phẩm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

