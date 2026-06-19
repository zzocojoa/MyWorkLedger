import 'package:flutter/services.dart';

final class ClockTimeInputFormatter extends TextInputFormatter {
  const ClockTimeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = _clockInputDigits(value: newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final String limitedDigits = digits.length > 4
        ? digits.substring(0, 4)
        : digits;
    final String formattedValue = _formatClockInputDigitsForEditing(
      digits: limitedDigits,
    );
    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}

String normalizeClockInput({required String value}) {
  final String trimmedValue = value.trim();
  if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(trimmedValue)) {
    final List<String> parts = trimmedValue.split(':');
    final String hour = parts[0].padLeft(2, '0');
    final String minute = parts[1];
    return '$hour:$minute';
  }
  final String digits = _clockInputDigits(value: trimmedValue);
  if (digits.length == 3) {
    return '${digits.substring(0, 1).padLeft(2, '0')}:${digits.substring(1)}';
  }
  if (digits.length == 4) {
    return '${digits.substring(0, 2)}:${digits.substring(2)}';
  }
  return trimmedValue;
}

String _clockInputDigits({required String value}) {
  return value.replaceAll(RegExp(r'[^0-9]'), '');
}

String _formatClockInputDigitsForEditing({required String digits}) {
  if (digits.length <= 3) {
    return digits;
  }
  return '${digits.substring(0, 2)}:${digits.substring(2)}';
}
