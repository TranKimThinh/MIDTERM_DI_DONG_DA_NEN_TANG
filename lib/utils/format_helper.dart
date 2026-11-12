class FormatHelper {
  static String formatCurrency(num value) {
    final rounded = value.round();
    final isNegative = rounded < 0;
    final digits = rounded.abs().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      if (i > 0 && reverseIndex % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    return '${isNegative ? '-' : ''}${buffer.toString()} đ';
  }

  static String formatNumber(int value) {
    final isNegative = value < 0;
    final digits = value.abs().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      if (i > 0 && reverseIndex % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    return '${isNegative ? '-' : ''}$buffer';
  }
}
