import 'package:intl/intl.dart';

import '../../domain/entities/service_category.dart';

/// Central formatting helpers so currency/locale changes happen in one place.
abstract final class Formatters {
  static final _money = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
  static final _moneyPrecise = NumberFormat.currency(symbol: r'$');

  static String money(double value) =>
      value == value.roundToDouble() ? _money.format(value) : _moneyPrecise.format(value);

  static String duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  static String day(DateTime date) => DateFormat('EEE, d MMM').format(date);

  static String dayLong(DateTime date) => DateFormat('EEEE, d MMMM').format(date);

  static String time(DateTime date) => DateFormat('HH:mm').format(date);

  static String distance(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
}

/// Icon-name mapping lives with the presentation helpers, keeping the
/// domain enum free of Flutter imports.
extension ServiceCategoryX on ServiceCategory {
  String get emoji => switch (this) {
        ServiceCategory.haircut => '💇',
        ServiceCategory.barber => '💈',
        ServiceCategory.nails => '💅',
        ServiceCategory.spa => '🧖',
        ServiceCategory.makeup => '💄',
        ServiceCategory.skincare => '✨',
      };
}
