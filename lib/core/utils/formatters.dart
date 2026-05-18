import 'package:intl/intl.dart';

class AppFormatters {
  static const _locale = 'pt_BR';

  static final NumberFormat _currency = NumberFormat.currency(
    locale: _locale,
    symbol: 'R\$',
  );
  static final NumberFormat _quantity = NumberFormat('#,##0.##', _locale);
  static final NumberFormat _compact = NumberFormat.compact(locale: _locale);
  static final DateFormat _date = DateFormat('dd/MM/yyyy', _locale);
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm', _locale);

  static String currency(double value) => _currency.format(value);

  static String quantity(double value) => _quantity.format(value);

  static String compactNumber(double value) => _compact.format(value);

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  static double parseDecimal(String rawValue) {
    var normalized = rawValue.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    normalized = normalized.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (normalized.isEmpty) {
      return 0;
    }

    final isNegative = normalized.startsWith('-');
    normalized = normalized.replaceAll('-', '');
    if (normalized.isEmpty) {
      return 0;
    }

    if (normalized.contains(',') && normalized.contains('.')) {
      final lastComma = normalized.lastIndexOf(',');
      final lastDot = normalized.lastIndexOf('.');
      if (lastComma > lastDot) {
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    } else if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      final dotMatches = RegExp(r'\.').allMatches(normalized).length;
      if (dotMatches > 1) {
        final separatorIndex = normalized.lastIndexOf('.');
        normalized =
            normalized.substring(0, separatorIndex).replaceAll('.', '') +
            normalized.substring(separatorIndex);
      }
    }

    if (isNegative) {
      normalized = '-$normalized';
    }

    return double.parse(normalized);
  }
}
