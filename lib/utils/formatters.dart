// ============================================================
// utils/formatters.dart
// Utility functions for formatting currency, dates, etc.
// ============================================================

import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  // Currency formatter (USD)
  static final _currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  // Short currency (no cents for large numbers)
  static final _shortCurrencyFormatter = NumberFormat.compactCurrency(
    symbol: '\$',
    decimalDigits: 1,
  );

  /// Format a double as currency string: 1234.5 → "$1,234.50"
  static String currency(double amount) {
    return _currencyFormatter.format(amount);
  }

  /// Format a double as compact currency: 4500.0 → "$4.5K"
  static String currencyCompact(double amount) {
    if (amount.abs() < 10000) return _currencyFormatter.format(amount);
    return _shortCurrencyFormatter.format(amount);
  }

  /// Format a DateTime as "Jan 15, 2025"
  static String dateShort(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Format a DateTime as "January 15, 2025"
  static String dateLong(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  /// Format a DateTime as "Mon, Jan 15"
  static String dateMedium(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  /// Returns "Today", "Yesterday", or formatted date
  static String dateRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';
    return dateShort(date);
  }
}
