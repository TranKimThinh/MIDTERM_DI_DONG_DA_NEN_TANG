import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<ImagePickResult> pickImageAsBase64(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 420,
        maxHeight: 420,
        imageQuality: 55,
      );

      if (file == null) {
        return const ImagePickResult.cancelled();
      }

      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return const ImagePickResult.error('Không đọc được dữ liệu hình ảnh.');
      }

      if (bytes.lengthInBytes > 650 * 1024) {
        return const ImagePickResult.error(
          'Ảnh quá lớn (> 650 KB). Vui lòng chọn ảnh nhẹ hơn hoặc dùng URL.',
        );
      }

      final lowerName = file.name.toLowerCase();
      final mime = lowerName.endsWith('.png') ? 'image/png' : 'image/jpeg';
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      return ImagePickResult.success(dataUri);
    } catch (e) {
      return ImagePickResult.error('Không thể chọn ảnh: $e');
    }
  }

  static Uint8List? decodeBase64Image(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    try {
      if (trimmed.startsWith('data:image')) {
        final commaIndex = trimmed.indexOf(',');
        if (commaIndex == -1) return null;
        return base64Decode(trimmed.substring(commaIndex + 1));
      }
      if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
        return base64Decode(trimmed);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool isNetworkUrl(String value) {
    final trimmed = value.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  static bool isBase64DataUri(String value) {
    return value.trim().startsWith('data:image');
  }
}

class ImagePickResult {
  final String? dataUri;
  final String? error;
  final bool cancelled;

  const ImagePickResult.success(this.dataUri) : error = null, cancelled = false;

  const ImagePickResult.error(this.error) : dataUri = null, cancelled = false;

  const ImagePickResult.cancelled()
    : dataUri = null,
      error = null,
      cancelled = true;
}
