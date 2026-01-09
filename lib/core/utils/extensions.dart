import 'package:intl/intl.dart';

/// Extension methods for common operations

// String Extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
}

// DateTime Extensions
extension DateTimeExtensions on DateTime {
  /// Format date as 'dd MMM yyyy'
  String toFormattedDate() {
    return DateFormat('dd MMM yyyy').format(this);
  }

  /// Format date as 'dd/MM/yyyy'
  String toShortDate() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// Format date and time as 'dd MMM yyyy, HH:mm'
  String toFormattedDateTime() {
    return DateFormat('dd MMM yyyy, HH:mm').format(this);
  }
}

// Number Extensions
extension DoubleExtensions on double {
  /// Format as currency
  String toCurrency({String symbol = '\$'}) {
    return '$symbol${toStringAsFixed(2)}';
  }
}

extension IntExtensions on int {
  /// Format as currency
  String toCurrency({String symbol = '\$'}) {
    return '$symbol${toStringAsFixed(2)}';
  }
}
