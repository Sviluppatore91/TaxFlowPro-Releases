import 'package:intl/intl.dart';
import 'dart:math';

/// Utility class for currency parsing, formatting, and mathematical rounding.
/// Ensures that financial calculations use a consistent rounding approach
/// and that UI formatting is identical across the app.
class CurrencyUtils {
  static final NumberFormat _euroFormat = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '€',
    decimalDigits: 2,
  );

  /// Parses a string into a double, handling both comma and dot decimal separators.
  /// If the input is empty or invalid, returns 0.0.
  /// Example: "1.234,56" -> 1234.56
  static double parseCurrency(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 0.0;
    }

    String cleaned = input.trim();
    
    // Support division input like "1300/2"
    if (cleaned.contains('/')) {
      final parts = cleaned.split('/');
      if (parts.length == 2) {
        final num1 = parseCurrency(parts[0]);
        final num2 = parseCurrency(parts[1]);
        if (num2 != 0) {
          return roundMoney(num1 / num2);
        }
      }
      return 0.0;
    }

    // Handle Italian formatting (1.234,56 -> 1234.56)
    // First, check if both . and , are present
    if (cleaned.contains('.') && cleaned.contains(',')) {
      // If dot is before comma, it's likely thousand separator dot, decimal comma
      if (cleaned.indexOf('.') < cleaned.indexOf(',')) {
        cleaned = cleaned.replaceAll('.', '');
        cleaned = cleaned.replaceAll(',', '.');
      } else {
        // comma is before dot (e.g. 1,234.56)
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains(',')) {
      // Only comma present, assume it's decimal comma
      cleaned = cleaned.replaceAll(',', '.');
    }

    // Remove any remaining characters that are not digits, dot, or minus sign
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9\.-]'), '');

    double? parsed = double.tryParse(cleaned);
    if (parsed == null) return 0.0;
    
    return roundMoney(parsed);
  }

  /// Formats a double for UI display according to custom rules:
  /// - Comma for decimals instead of dot.
  /// - Dot for thousands separator ONLY if the number is > 9999.
  /// Example: 1500.50 -> "1500,50"
  /// Example: 10000.50 -> "10.000,50"
  static String formatUI(num amount, {int decimals = 2}) {
    double rounded = roundMoney(amount.toDouble());
    bool isNegative = rounded < 0;
    String str = rounded.abs().toStringAsFixed(decimals);
    
    List<String> parts = str.split('.');
    String intPart = parts[0];
    String decPart = parts.length > 1 ? parts[1] : '';
    
    // Add dot for thousands ONLY if intPart is longer than 4 digits (>= 10000)
    if (intPart.length > 4) {
      String formattedInt = '';
      int count = 0;
      for (int i = intPart.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) {
          formattedInt = '.' + formattedInt;
        }
        formattedInt = intPart[i] + formattedInt;
        count++;
      }
      intPart = formattedInt;
    }
    
    String result = decPart.isNotEmpty ? '$intPart,$decPart' : intPart;
    if (isNegative) {
      result = '-' + result;
    }
    return result;
  }

  /// Formats a double into a standard Euro string representation.
  /// Example: 1234.567 -> "€ 1234,57" (or with dots if >= 10000)
  static String formatEuro(num amount) {
    return '€ ${formatUI(amount)}';
  }

  /// Performs mathematical rounding to 2 decimal places to prevent floating-point accumulation errors.
  /// Example: 0.1 + 0.2 (0.30000000000000004) -> 0.30
  static double roundMoney(double value) {
    double mod = pow(10.0, 2).toDouble();
    return ((value * mod).round().toDouble() / mod);
  }
}
